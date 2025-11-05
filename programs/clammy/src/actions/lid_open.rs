use crate::state::State;
use crate::wayland_manager::WlDelegate;
use crate::wayland_output::{find_head_by_name, find_preferred_mode};
use anyhow::{anyhow, Result};
use log::{debug, info, warn};
use wayland_client::QueueHandle;
use wayland_protocols_wlr::output_management::v1::client::zwlr_output_configuration_v1;

/// Applies a lid-open configuration (eDP on, externals on)
pub fn apply_lid_open_config(
    state: &State,
    delegate: &WlDelegate,
    config: &zwlr_output_configuration_v1::ZwlrOutputConfigurationV1,
    qh: &QueueHandle<WlDelegate>,
) -> Result<()> {
    info!("Applying lid open mode configuration...");
    let mut x_offset = 0;

    // 1. Enable and position eDP leftmost
    if let Some(edp_monitor) = &state.edp_name {
        if let Some(head) = find_head_by_name(delegate, &edp_monitor.name) {
            if let Some(mode) = find_preferred_mode(delegate, head) {
                debug!(
                    "Enabling eDP: {} at x=0 with mode {}x{}",
                    edp_monitor.name, mode.width, mode.height
                );
                let config_head = config.enable_head(head);
                config_head.set_mode(&mode.wl_mode.unwrap());
                config_head.set_position(0, 0);
                x_offset += mode.width;
            } else {
                warn!("Could not find preferred mode for eDP '{}'", edp_monitor.name);
            }
        } else {
            warn!("Could not find eDP head named '{}' to enable.", edp_monitor.name);
        }
    }

    // 2. Position external monitors after eDP
    for monitor in &state.external_monitors {
        if let Some(head) = find_head_by_name(delegate, &monitor.name) {
            if let Some(mode) = find_preferred_mode(delegate, head) {
                debug!(
                    "Enabling external monitor: {} at x={} with mode {}x{}",
                    monitor.name, x_offset, mode.width, mode.height
                );
                let config_head = config.enable_head(head);
                config_head.set_mode(&mode.wl_mode.unwrap());
                config_head.set_position(x_offset, 0);
                x_offset += mode.width;
            } else {
                warn!("Could not find preferred mode for monitor '{}'", monitor.name);
            }
        } else {
            warn!("Could not find head for monitor '{}'", monitor.name);
        }
    }

    config.apply();
    Ok(())
}
