// === ./programs/clammy/src/actions/dpms.rs ===
//! Implements DPMS (display power saving) actions.

use crate::wayland_manager::WlDelegate;
use anyhow::{anyhow, Result};
use log::{debug, info, trace};
use wayland_client::QueueHandle;

/// Turns all active displays off (DPMS).
pub fn dpms_off(delegate: &WlDelegate, qh: &QueueHandle<WlDelegate>) -> Result<()> {
    info!("Turning displays OFF (DPMS)");
    let manager = delegate
        .output_manager
        .as_ref()
        .ok_or(anyhow!("Output manager not bound"))?;

    // We create a new configuration and apply it
    let config = manager.create_configuration(0, qh, ());

    // Iterate over all known heads from the last parse
    for head in delegate.temp_heads.keys() {
        let info = delegate.temp_heads.get(head).unwrap(); // Must exist
        if info.active {
            trace!("DPMS OFF: Disabling head '{}'", info.name);
            config.disable_head(head);
        }
    }

    config.apply();

    // Update the shared state
    delegate.state.lock().unwrap().displays_off = true;
    Ok(())
}

/// Turns all displays on (DPMS).
pub fn dpms_on(delegate: &WlDelegate, qh: &QueueHandle<WlDelegate>) -> Result<()> {
    info!("Turning displays ON (DPMS)");
    let manager = delegate
        .output_manager
        .as_ref()
        .ok_or(anyhow!("Output manager not bound"))?;

    // To turn displays on, we *must* re-apply a valid configuration.
    // We check the lid state to see which configuration to apply.
    let config = manager.create_configuration(0, qh, ());
    let state = delegate.state.lock().unwrap();

    if state.lid_closed {
        // Lid is closed, so re-apply clamshell mode
        debug!("DPMS ON: Lid is closed, re-applying clamshell config.");
        super::clamshell::apply_clamshell_config(&state, delegate, config, qh)?;
    } else {
        // Lid is open, so re-apply standard "lid open" mode
        debug!("DPMS ON: Lid is open, re-applying lid_open config.");
        super::lid_open::apply_lid_open_config(&state, delegate, config, qh)?;
    }
    
    // The individual apply_... functions will call config.apply()
    state.displays_off = false;
    Ok(())
}
