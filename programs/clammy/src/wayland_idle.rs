use crate::commands::DbusCommand;
use crate::config;
use crate::wayland_manager::WlDelegate;
use crate::{actions, wayland_output};
use anyhow::Result;
use log::{debug, error, info, trace};
use wayland_client::{Connection, Dispatch, QueueHandle};
use wayland_protocols::ext::idle_notify::v1::client::{
    ext_idle_notification_v1, ext_idle_notifier_v1,
};

/// Creates the two idle timers (DPMS and Sleep)
pub fn create_idle_timers(delegate: &mut WlDelegate, qh: &QueueHandle<WlDelegate>) -> Result<()> {
    if let Some(notifier) = &delegate.idle_notifier {
        let seat = delegate.seat.as_ref().ok_or(anyhow::anyhow!("No seat available"))?;
        info!("Creating idle timers...");

        // 1. DPMS timer
        let dpms_timeout_ms = config::idle_timeout_s() * 1000;
        let dpms_timer = notifier.get_idle_notification(dpms_timeout_ms, seat, qh, ());
        delegate.idle_timer_dpms = Some(dpms_timer);

        // 2. Sleep timer (relative to DPMS)
        let sleep_timeout_ms = (config::idle_timeout_s() + config::sleep_timeout_s()) * 1000;
        let sleep_timer = notifier.get_idle_notification(sleep_timeout_ms, seat, qh, ());
        delegate.idle_timer_sleep = Some(sleep_timer);

        info!("Idle timers created: {}ms (DPMS), {}ms (Sleep)", dpms_timeout_ms, sleep_timeout_ms);
    }
    Ok(())
}


impl Dispatch<ext_idle_notifier_v1::ExtIdleNotifierV1, ()> for WlDelegate {
    fn event(
        _state: &mut Self,
        _notifier: &ext_idle_notifier_v1::ExtIdleNotifierV1,
        event: ext_idle_notifier_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
        trace!("ext_idle_notifier_v1 event: {:?}", event);
    }
}

impl Dispatch<ext_idle_notification_v1::ExtIdleNotificationV1, ()> for WlDelegate {
    fn event(
        state: &mut Self,
        notification: &ext_idle_notification_v1::ExtIdleNotificationV1,
        event: ext_idle_notification_v1::Event,
        _data: &(),
        _conn: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        let is_dpms_timer = state.idle_timer_dpms.as_ref() == Some(notification);
        let is_sleep_timer = state.idle_timer_sleep.as_ref() == Some(notification);

        match event {
            ext_idle_notification_v1::Event::Idled => {
                // Check if the lid is closed. If so, do nothing.
                if state.state.lock().unwrap().lid_closed {
                    debug!("Idle timer fired, but lid is closed. Ignoring.");
                    return;
                }

                if is_dpms_timer {
                    info!("Idle timer (DPMS) fired: IDLED");
                    // Point 3: Lock screen and turn displays off
                    if let Err(e) = actions::lock::request_lock() {
                        error!("Failed to request lock on idle: {}", e);
                    }
                    if let Err(e) = wayland_output::dpms_off(state, qh) {
                        error!("Failed to turn displays off on idle: {}", e);
                    }
                }
                if is_sleep_timer {
                    info!("Idle timer (Sleep) fired: IDLED");
                    // Point 3: Send command to main thread to suspend
                    match state.suspend_tx.blocking_send(DbusCommand::RequestSuspend) {
                        Ok(_) => info!("Sent RequestSuspend to D-Bus thread."),
                        Err(e) => error!("Failed to send RequestSuspend: {}", e),
                    }
                }
            }
            ext_idle_notification_v1::Event::Resumed => {
                if is_dpms_timer {
                    info!("Idle timer (DPMS) fired: RESUMED");
                    // We only turn displays on if they were off
                    if state.state.lock().unwrap().displays_off {
                         if let Err(e) = wayland_output::dpms_on(state, qh) {
                            error!("Failed to turn displays on on resume: {}", e);
                        }
                    }
                }
                if is_sleep_timer {
                    info!("Idle timer (Sleep) fired: RESUMED");
                }
            }
            _ => {}
        }
    }
}
