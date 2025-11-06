use crate::wayland_manager::WlDelegate;
use anyhow::{anyhow, Result};
use log::{debug, info, warn, trace};
use wayland_client::{delegate_noop, Connection, Dispatch, QueueHandle};
use wayland_protocols::ext::session_lock::v1::client::{
    ext_session_lock_manager_v1, ext_session_lock_v1,
};

/// Sends a request to the compositor to lock the screen.
pub fn request_lock(
    delegate: &mut WlDelegate,
    qh: &QueueHandle<WlDelegate>,
) -> Result<()> {
    if delegate.current_lock.is_some() {
        warn!("Lock already active, not requesting new lock.");
        return Ok(());
    }

    if let Some(manager) = &delegate.lock_manager {
        info!("Requesting session lock...");
        let lock = manager.lock(qh, ());
        delegate.current_lock = Some(lock);
        Ok(())
    } else {
        Err(anyhow!("Session lock manager is not available"))
    }
}

// --- Dispatch Implementations ---
impl Dispatch<ext_session_lock_manager_v1::ExtSessionLockManagerV1, ()> for WlDelegate {
    fn event(
        _state: &mut Self,
        _manager: &ext_session_lock_manager_v1::ExtSessionLockManagerV1,
        event: ext_session_lock_manager_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
        trace!("ext_session_lock_manager_v1 event: {:?}", event);
    }
}

impl Dispatch<ext_session_lock_v1::ExtSessionLockV1, ()> for WlDelegate {
    fn event(
        state: &mut Self,
        lock: &ext_session_lock_v1::ExtSessionLockV1,
        event: ext_session_lock_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
        match event {
            ext_session_lock_v1::Event::Locked => {
                info!("Session is now locked.");
                // We could update state here if needed
                // state.state.lock().unwrap().displays_off = true;
            }
            ext_session_lock_v1::Event::Finished => {
                info!("Session lock finished (unlocked).");
                state.current_lock = None;
                lock.destroy();
            }
            _ => {}
        }
    }
}
