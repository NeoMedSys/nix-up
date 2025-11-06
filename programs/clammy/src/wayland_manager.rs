use crate::commands::{DbusCommand, WaylandCommand};
use crate::config;
use crate::wayland_output::HeadInfo;
use crate::{actions, state::SharedState, wayland_idle, wayland_output};
use anyhow::{anyhow, Context, Result};
use log::{debug, error, info, warn};
use polling::{Event, Events, Poller};
use std::cell::RefCell;
use std::collections::HashMap;
use std::os::fd::AsRawFd;
use std::time::Duration;
use std::os::fd::AsFd;
use std::rc::Rc;
use std::sync::mpsc::Receiver;
use tokio::sync::mpsc::Sender as TokioSender;
use wayland_client::{
    delegate_noop,
    globals::registry_queue_init,
    protocol::{wl_output, wl_seat, wl_registry},
    Connection, Dispatch, QueueHandle,
};
use wayland_protocols::ext::idle_notify::v1::client::{
    ext_idle_notification_v1, ext_idle_notifier_v1,
};
use wayland_protocols_wlr::output_management::v1::client::{
    zwlr_output_head_v1, zwlr_output_manager_v1,
};

// --- The Central Delegate Struct ---
#[derive(Debug)]
pub struct WlDelegate {
    pub state: SharedState,
    pub output_manager: Option<zwlr_output_manager_v1::ZwlrOutputManagerV1>,
    pub idle_notifier: Option<ext_idle_notifier_v1::ExtIdleNotifierV1>,
    pub seat: Option<wl_seat::WlSeat>,
    pub heads: HashMap<wl_output::WlOutput, zwlr_output_head_v1::ZwlrOutputHeadV1>,
    pub idle_timer_dpms: Option<ext_idle_notification_v1::ExtIdleNotificationV1>,
    pub idle_timer_sleep: Option<ext_idle_notification_v1::ExtIdleNotificationV1>,
    pub temp_heads: HashMap<zwlr_output_head_v1::ZwlrOutputHeadV1, Rc<RefCell<HeadInfo>>>,
    pub suspend_tx: TokioSender<DbusCommand>,
}

/// pub seat: Option<wl_seat::WlSeat>,
/// Connects to Wayland and runs the event loop.
pub fn run_wayland_listener(
    state: SharedState,
    cmd_rx: Receiver<WaylandCommand>,
    suspend_tx: TokioSender<DbusCommand>,
) -> Result<()> {
    info!("Connecting to Wayland display...");
    let conn = Connection::connect_to_env().context("Failed to connect to WAYLAND_DISPLAY")?;

    let mut wl_delegate = WlDelegate {
        state,
        suspend_tx,
        output_manager: None,
        idle_notifier: None,
        seat: None,
        heads: HashMap::new(),
        idle_timer_dpms: None,
        idle_timer_sleep: None,
        temp_heads: HashMap::new(),
    };

    let mut event_queue = conn.new_event_queue();
    let qh = event_queue.handle();
    let display = conn.display();
        
    debug!("Getting registry...");
    let _registry = display.get_registry(&qh, ());

    debug!("Performing initial Wayland roundtrip...");
    event_queue
        .roundtrip(&mut wl_delegate)
        .context("Failed initial Wayland roundtrip")?;
    debug!("Roundtrip completed. Checking protocols...");

    // --- Check for necessary protocols ---
    if wl_delegate.output_manager.is_none() {
        return Err(anyhow!("Compositor does not support zwlr_output_manager_v1"));
    }
    if wl_delegate.idle_notifier.is_none() {
        warn!("Compositor does not support ext_idle_notify_v1. Idle/DPMS will not work.");
    }

    // --- Initial Setup ---
    if let Err(e) = wayland_idle::create_idle_timers(&mut wl_delegate, &event_queue.handle()) {
        error!("Failed to create idle timers: {}", e);
    }

    info!("Wayland listener started. Running event loop...");

    // --- The Poll Loop (Using keys from config) ---
    let wl_fd = conn.as_fd();

    let poller = Poller::new()?;
    unsafe {
        poller.add(&wl_fd, Event::readable(config::WAYLAND_KEY))?;
    }

    let mut events = Events::new();

    loop {
        events.clear();
        poller.wait(&mut events, Some(std::time::Duration::from_millis(100))).context("Poller failed")?;

        for event in events.iter() {
            if event.key == config::WAYLAND_KEY {
                debug!("Event: Wayland event received");
                // For wayland-client 0.31, we just dispatch
                event_queue
                    .dispatch_pending(&mut wl_delegate)
                    .context("Wayland dispatch failed")?;
            }
        }

        // Check for MPSC commands (non-blocking)
        match cmd_rx.try_recv() {
            Ok(WaylandCommand::LidClosed) => {
                info!("Wayland thread: Received LidClosed command");
                let mut guard = wl_delegate.state.lock().unwrap();
                guard.lid_closed = true;

                if let Err(e) = wayland_output::configure_clamshell(
                    &guard,
                    &wl_delegate,
                    &event_queue.handle(),
                ) {
                    error!("Failed to configure clamshell: {}", e);
                }
            }
            Ok(WaylandCommand::LidOpened) => {
                info!("Wayland thread: Received LidOpened command");
                let mut guard = wl_delegate.state.lock().unwrap();
                guard.lid_closed = false;

                info!("Lid opened, requesting lock.");
                actions::lock::request_lock();

                if let Err(e) = wayland_output::configure_lid_open(
                    &guard,
                    &wl_delegate,
                    &event_queue.handle(),
                ) {
                    error!("Failed to configure lid open: {}", e);
                }
            }
            Err(std::sync::mpsc::TryRecvError::Disconnected) => {
                error!("MPSC channel disconnected. Exiting.");
                return Err(anyhow!("Main thread disconnected"));
            }
            _ => {}
        }

        // Re-arm the poller
        poller.modify(&wl_fd, Event::readable(config::WAYLAND_KEY))?;
    }
}

// --- Dispatch Implementations ---

impl Dispatch<wl_registry::WlRegistry, ()> for WlDelegate {
    fn event(
        state: &mut Self,
        registry: &wl_registry::WlRegistry,
        event: wl_registry::Event,
        _data: &(),
        _conn: &Connection,
        queue_handle: &QueueHandle<Self>,
    ) {
        debug!("Registry event received: {:?}", event);
        if let wl_registry::Event::Global {
            name,
            interface,
            version,
        } = event
        {
            debug!("Wayland global: [{}] {} (v{})", name, interface, version);
            match interface.as_str() {
                "zwlr_output_manager_v1" => {
                    state.output_manager =
                        Some(registry.bind(name, 1.min(version), queue_handle, ()));
                }
                "ext_idle_notifier_v1" => {
                    state.idle_notifier =
                        Some(registry.bind(name, 1.min(version), queue_handle, ()));
                }
                "wl_seat" => {
                    state.seat = Some(registry.bind(name, 1.min(version), queue_handle, ()));
                }
                "wl_output" => {
                    let _output = registry.bind::<wl_output::WlOutput, _, _>(
                        name,
                        1.min(version),
                        queue_handle,
                        (),
                    );
                }
                _ => {}
            }
        }
    }
}

delegate_noop!(WlDelegate: wl_output::WlOutput);
delegate_noop!(WlDelegate: wl_seat::WlSeat);
