use crate::commands::{DbusCommand, WaylandCommand};
use crate::config;
use crate::{actions, state::SharedState, wayland_idle, wayland_output};
use anyhow::{Context, Result};
use log::{error, info};
use polling::{Event, Events, Poller};
use std::os::fd::AsFd;
use tokio::sync::mpsc::Sender as TokioSender;
use std::sync::mpsc::Receiver;
use wayland_client::{
    protocol::{wl_seat, wl_registry},
    Connection, Dispatch, QueueHandle,
};
use wayland_protocols::ext::idle_notify::v1::client::{
    ext_idle_notification_v1, ext_idle_notifier_v1,
};


#[derive(Debug)]
pub struct WlDelegate {
    pub state: SharedState,
    pub idle_notifier: Option<ext_idle_notifier_v1::ExtIdleNotifierV1>,
    pub seat: Option<wl_seat::WlSeat>,
    pub idle_timer_dim_start: Option<ext_idle_notification_v1::ExtIdleNotificationV1>,
    pub idle_timer_dpms: Option<ext_idle_notification_v1::ExtIdleNotificationV1>,
    pub idle_timer_sleep: Option<ext_idle_notification_v1::ExtIdleNotificationV1>,
    pub idle_timer_dpms_off: Option<ext_idle_notification_v1::ExtIdleNotificationV1>,
    pub suspend_tx: TokioSender<DbusCommand>,
}

pub fn run_wayland_listener(
    state: SharedState,
    cmd_rx: Receiver<WaylandCommand>,
    suspend_tx: TokioSender<DbusCommand>,
) -> Result<()> {
    let conn = Connection::connect_to_env().context("Failed to connect to WAYLAND_DISPLAY")?;
    let mut wl_delegate = WlDelegate {
        state,
        suspend_tx,
        idle_notifier: None,
        seat: None,
        idle_timer_dim_start: None,
        idle_timer_dpms: None,
        idle_timer_dpms_off: None,
        idle_timer_sleep: None,
    };

    let mut event_queue = conn.new_event_queue();
    let qh = event_queue.handle();
    let _registry = conn.display().get_registry(&qh, ());

    event_queue.roundtrip(&mut wl_delegate)?;

    // Initial Niri State Scan
    let _ = wayland_output::scan_outputs(&wl_delegate.state);

    if let Err(e) = wayland_idle::create_idle_timers(&mut wl_delegate, &qh) {
        error!("Failed to create idle timers: {}", e);
    }

    event_queue.roundtrip(&mut wl_delegate)?;

    let poller = Poller::new()?;
    unsafe { poller.add(&conn.as_fd(), Event::readable(config::WAYLAND_KEY))?; }
    let mut events = Events::new();

    loop {
        events.clear();
        poller.wait(&mut events, Some(std::time::Duration::from_millis(100)))?;

        for event in events.iter() {
            if event.key == config::WAYLAND_KEY {
                event_queue.blocking_dispatch(&mut wl_delegate)?;
            }
        }

        // In the match cmd_rx.try_recv() block, add logging:

        match cmd_rx.try_recv() {
            Ok(WaylandCommand::LidClosed) => {
                info!("Wayland thread: Received LidClosed command");
                let mut guard = wl_delegate.state.lock().unwrap();
                guard.lid_closed = true;
                drop(guard); // Release lock before calling configure
                let guard = wl_delegate.state.lock().unwrap();
                if let Err(e) = wayland_output::configure_clamshell(&guard, &wl_delegate, &qh) {
                    error!("Failed to configure clamshell: {}", e);
                }
            }
            Ok(WaylandCommand::LidOpened) => {
                info!("Wayland thread: Received LidOpened command");
                let mut guard = wl_delegate.state.lock().unwrap();
                guard.lid_closed = false;
                drop(guard);
                if let Err(e) = actions::lock::request_lock() {
                    error!("Failed to request lock: {}", e);
                }
                let guard = wl_delegate.state.lock().unwrap();
                if let Err(e) = wayland_output::configure_lid_open(&guard, &wl_delegate, &qh) {
                    error!("Failed to configure lid open: {}", e);
                }
            }
            _ => {}
        }
        poller.modify(&conn.as_fd(), Event::readable(config::WAYLAND_KEY))?;
    }
}

// Dispatch Implementations for Registry, Seat, and Idle (NO CHANGES NEEDED TO IDLE LOGIC)
impl Dispatch<wl_registry::WlRegistry, ()> for WlDelegate {
    fn event(state: &mut Self, registry: &wl_registry::WlRegistry, event: wl_registry::Event, _: &(), _: &Connection, qh: &QueueHandle<Self>) {
        if let wl_registry::Event::Global { name, interface, version } = event {
            match interface.as_str() {
                "ext_idle_notifier_v1" => { state.idle_notifier = Some(registry.bind(name, 1, qh, ())); }
                "wl_seat" => { state.seat = Some(registry.bind(name, 1, qh, ())); }
                _ => {}
            }
        }
    }
}



impl Dispatch<wl_seat::WlSeat, ()> for WlDelegate {
    fn event(_: &mut Self, _: &wl_seat::WlSeat, _: wl_seat::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
}
