use crate::state::State;
use crate::wayland_manager::WlDelegate;
use crate::wayland_output::{find_head_by_name, find_preferred_mode};
use anyhow::Result;
use log::{debug, info, warn};
use wayland_client::QueueHandle;
use wayland_protocols_wlr::output_management::v1::client::zwlr_output_configuration_v1;

pub fn apply_clamshell_config(
    state: &State,
    delegate: &WlDelegate,
    config: &zwlr_output_configuration_v1::ZwlrOutputConfigurationV1,
    qh: &QueueHandle<WlDelegate>,
) -> Result<()> {
    info!("Applying clamshell mode configuration...");

    // 1. Disable eDP
    if let Some(edp_monitor) = &state.edp_name {
        if let Some(head) = find_head_by_name(delegate, &edp_monitor.name) {
            debug!("Disabling eDP: {}", edp_monitor.name);
            config.disable_head(head);
        } else {
            warn!("Could not find eDP head named '{}' to disable.", edp_monitor.name);
        }
    }

    // 2. Enable and position external monitors
    let mut x_offset = 0;
    for monitor in &state.external_monitors {
        if let Some(head) = find_head_by_name(delegate, &monitor.name) {
            if let Some(mode) = find_preferred_mode(delegate, head) {
                debug!(
                    "Enabling external monitor: {} at x={} with mode {}x{}",
                    monitor.name, x_offset, mode.width, mode.height
                );
                let config_head = config.enable_head(head, qh, ());
                config_head.set_mode(&mode.wl_mode.unwrap()); // We unwrap, as it must be Some
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
