use crate::state::{Monitor, State};
use crate::wayland_manager::WlDelegate;
use anyhow::{anyhow, Result};
use log::{debug, error, info, trace, warn};
use std::cell::RefCell;
use std::rc::Rc;
use wayland_client::{delegate_noop, event_created_child,  protocol::wl_output, Connection, Dispatch, QueueHandle, Proxy};
use wayland_protocols_wlr::output_management::v1::client::{
    zwlr_output_configuration_head_v1, zwlr_output_configuration_v1, zwlr_output_head_v1,
    zwlr_output_manager_v1, zwlr_output_mode_v1,
};
use crate::actions;
use crate::commands::DbusCommand;

// --- Temporary structs for parsing ---
#[derive(Debug, Default, Clone)]
pub struct HeadInfo {
    pub wl_output: Option<wl_output::WlOutput>,
    pub name: String,
    pub description: String,
    pub active: bool,
    pub modes: Vec<ModeInfo>,
    pub preferred_mode: Option<ModeInfo>,
}

#[derive(Debug, Clone, Default)]
pub struct ModeInfo {
    pub wl_mode: Option<zwlr_output_mode_v1::ZwlrOutputModeV1>,
    pub width: i32,
    pub height: i32,
    pub is_preferred: bool,
}

// --- Public Functions ---

/// Turns all active displays off (DPMS).
pub fn dpms_off(delegate: &WlDelegate, qh: &QueueHandle<WlDelegate>) -> Result<()> {
    actions::dpms::dpms_off(delegate, qh)
}

/// Turns all displays on (DPMS).
pub fn dpms_on(delegate: &WlDelegate, qh: &QueueHandle<WlDelegate>) -> Result<()> {
    actions::dpms::dpms_on(delegate, qh)
}

/// Applies a clamshell configuration (eDP off, externals on)
pub fn configure_clamshell(
    state: &State,
    delegate: &WlDelegate,
    qh: &QueueHandle<WlDelegate>,
) -> Result<()> {
    let manager = delegate
        .output_manager
        .as_ref()
        .ok_or(anyhow!("Output manager not bound"))?;
    let config = manager.create_configuration(0, qh, ());
    actions::clamshell::apply_clamshell_config(state, delegate, &config, qh)
}

/// Applies a lid-open configuration (eDP on, externals on)
pub fn configure_lid_open(
    state: &State,
    delegate: &WlDelegate,
    qh: &QueueHandle<WlDelegate>,
) -> Result<()> {
    let manager = delegate
        .output_manager
        .as_ref()
        .ok_or(anyhow!("Output manager not bound"))?;
    let config = manager.create_configuration(0, qh, ());
    actions::lid_open::apply_lid_open_config(state, delegate, &config, qh)
}

/// Triggers a new scan of all outputs
pub fn scan_outputs(delegate: &mut WlDelegate, qh: &QueueHandle<WlDelegate>) -> Result<()> {
    debug!("Scanning outputs...");
    // In 0.31 API, we don't call get_heads - the manager automatically sends heads
    // We just need to do a roundtrip to get all the events
    Ok(())
}

// --- Helper functions (still needed here for actions) ---
pub fn find_head_by_name<'a>(
    delegate: &'a WlDelegate,
    name: &str,
) -> Option<&'a zwlr_output_head_v1::ZwlrOutputHeadV1> {
    delegate
        .temp_heads
        .iter()
        .find(|(_, info)| info.borrow().name == name)
        .map(|(head, _)| head)
}

pub fn find_preferred_mode<'a>(
    delegate: &'a WlDelegate,
    head: &zwlr_output_head_v1::ZwlrOutputHeadV1,
) -> Option<ModeInfo> {
    delegate
        .temp_heads
        .get(head)
        .and_then(|info| {
            let info_borrow = info.borrow();
            // try to get the preffered or fallback to first
            info_borrow.preferred_mode.clone().or(info_borrow.modes.first().cloned())
        })
}

// --- Dispatch Implementations ---

/// Handles events from the output manager
impl Dispatch<zwlr_output_manager_v1::ZwlrOutputManagerV1, ()> for WlDelegate {
    fn event(
        state: &mut Self,
        _manager: &zwlr_output_manager_v1::ZwlrOutputManagerV1,
        event: zwlr_output_manager_v1::Event,
        _data: &(),
        _conn: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        match event {
            zwlr_output_manager_v1::Event::Head { head } => {
                debug!("=== OUTPUT MANAGER: New head event ===");
                debug!("Head object: {:?}", head.id());
                let head_info = Rc::new(RefCell::new(HeadInfo::default()));
                state.temp_heads.insert(head, head_info);
                debug!("Total heads tracked: {}", state.temp_heads.len());
            }
            zwlr_output_manager_v1::Event::Done { serial } => {
                debug!("=== OUTPUT MANAGER: Done event (serial={}) ===", serial);
                debug!("Total temp_heads before parsing: {}", state.temp_heads.len());

                let mut edp: Option<Monitor> = None;
                let mut externals: Vec<Monitor> = Vec::new();

                for info_rc in state.temp_heads.values() {
                    let info = info_rc.borrow();
                    debug!("Parsing head: {} (Active: {})", info.name, info.active);

                    if !info.active {
                        debug!("Head {} is not active, skipping.", info.name);
                        continue;
                    }

                    let mode = info.preferred_mode.clone().or(info.modes.first().cloned());

                    if let Some(m) = mode {
                        let monitor = Monitor {
                            name: info.name.clone(),
                            width: m.width,
                            active: info.active,
                        };
                        debug!("Assembled Monitor: {:?}", monitor);
                        if info.name.starts_with("eDP") || info.name.starts_with("LVDS") {
                            edp = Some(monitor);
                        } else {
                            externals.push(monitor);
                        }
                    } else {
                        warn!("Head {} is active but has no modes?", info.name);
                    }
                }

                debug!("Raw monitor order from compositor: {:?}", externals.iter().map(|m| &m.name).collect::<Vec<_>>());
                externals.sort_by(|a, b| a.name.cmp(&b.name));
                info!("Parse complete: eDP={:?}, externals={:?}", edp, externals);

                // Update the global state
                {
                    let mut shared_state = state.state.lock().unwrap();
                    let old_has_externals = shared_state.has_externals();

                    shared_state.edp_name = edp;
                    shared_state.external_monitors = externals;

                    let new_has_externals = shared_state.has_externals();
                    let lid_is_closed = shared_state.lid_closed;

                    if lid_is_closed && old_has_externals && !new_has_externals {
                        info!("External monitor disconnected while lid is closed. Requesting suspend timer.");
                        match state.suspend_tx.blocking_send(DbusCommand::RequestLidClosedSuspend) {
                            Ok(_) => info!("Sent RequestLidClosedSuspend to D-Bus thread."),
                            Err(e) => error!("Failed to send RequestLidClosedSuspend: {}", e),
                        }
                    }
                }

                // Now that state is updated, re-apply the correct config
                let shared_state = state.state.lock().unwrap();
                if shared_state.lid_closed {
                    if let Err(e) = configure_clamshell(&shared_state, state, qh) {
                        error!("Failed to apply config after scan: {}", e);
                    }
                } else {
                    if let Err(e) = configure_lid_open(&shared_state, state, qh) {
                        error!("Failed to apply config after scan: {}", e);
                    }
                }
            }
            zwlr_output_manager_v1::Event::Finished => {
                error!("Output manager protocol finished. Clammy can no longer function.");
            }
            _ => {}
        }
    }

    event_created_child!(WlDelegate, zwlr_output_manager_v1::ZwlrOutputManagerV1, [
        zwlr_output_manager_v1::EVT_HEAD_OPCODE => (zwlr_output_head_v1::ZwlrOutputHeadV1, ())
    ]);
}

/// Handles events from a specific output head
impl Dispatch<zwlr_output_head_v1::ZwlrOutputHeadV1, ()> for WlDelegate {
    fn event(
        state: &mut Self,
        head: &zwlr_output_head_v1::ZwlrOutputHeadV1,
        event: zwlr_output_head_v1::Event,
        _user_data: &(),
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
    ) {
        let info_rc = match state.temp_heads.get(head) {
            Some(info) => info.clone(),
            None => return,
        };
        
        let mut info = info_rc.borrow_mut();
        match event {
            zwlr_output_head_v1::Event::Name { name } => {
                info!("!!! HEAD NAME EVENT: {} !!!", name);
                trace!("DEBUG: Head {:?} has name: {}", head.id(), name);
                info.name = name.to_string();
            }
            zwlr_output_head_v1::Event::Description { description } => {
                trace!("DEBUG: Head {:?} has desc: {}", head.id(), description);
                info.description = description.to_string();
            }
            zwlr_output_head_v1::Event::Enabled { enabled } => {
                trace!("DEBUG: Head {:?} enabled: {}", head.id(), enabled);
                info.active = enabled != 0;
            }
            zwlr_output_head_v1::Event::Mode { mode } => {
                trace!("DEBUG: Head {:?} has mode: {:?}", head.id(), mode.id());
                let mode_info = ModeInfo {
                    wl_mode: Some(mode),
                    ..Default::default()
                };
                info.modes.push(mode_info);
            }
            zwlr_output_head_v1::Event::Finished => {
                trace!("DEBUG: Head {:?} finished (unplugged)", head.id());
                drop(info); // Release borrow before removing
                state.temp_heads.remove(head);
            }
            _ => {}
        }
    }
    event_created_child!(WlDelegate, zwlr_output_head_v1::ZwlrOutputHeadV1, [
        zwlr_output_head_v1::EVT_MODE_OPCODE => (zwlr_output_mode_v1::ZwlrOutputModeV1, ())
    ]);
}

/// Handles events from a specific display mode

impl Dispatch<zwlr_output_mode_v1::ZwlrOutputModeV1, ()> for WlDelegate {
    fn event(
        state: &mut Self,
        mode: &zwlr_output_mode_v1::ZwlrOutputModeV1,
        event: zwlr_output_mode_v1::Event,
        _user_data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
        // Find which head this mode belongs to
        let head_info_rc = match state.temp_heads.values().find(|info| {
            info.borrow()
                .modes
                .iter()
                .any(|m| m.wl_mode.as_ref() == Some(mode))
        }) {
            Some(info) => info.clone(),
            None => {
                // This can happen if events are out of order.
                // We can't do anything without the parent head.
                return;
            }
        };

        // Get a mutable borrow of the HeadInfo
        let mut info = head_info_rc.borrow_mut();

        // Find the specific ModeInfo *mutably*
        let mode_info = match info
            .modes
            .iter_mut()
            .find(|m| m.wl_mode.as_ref() == Some(mode))
        {
            Some(m) => m,
            None => {
                // Should be impossible if Head::Mode event was processed correctly
                warn!("Mode {:?} event received but not found in head's list", mode.id());
                return;
            }
        };

        // Now we modify the ModeInfo *in place*
        match event {
            zwlr_output_mode_v1::Event::Size { width, height } => {
                trace!("DEBUG: Mode {:?} size: {}x{}", mode.id(), width, height);
                mode_info.width = width;
                mode_info.height = height;
            }
            zwlr_output_mode_v1::Event::Preferred => {
                trace!("DEBUG: Mode {:?} is preferred", mode.id());
                mode_info.is_preferred = true;
            }
            zwlr_output_mode_v1::Event::Finished => {
                trace!("DEBUG: Mode {:?} finished", mode.id());
                // The mode is fully populated.
                // If it's preferred, set it on the *parent* HeadInfo.
                if mode_info.is_preferred {
                    info.preferred_mode = Some(mode_info.clone());
                }
            }
            _ => {}
        }
    }
}


// No-op implementations for configuration objects

// Handles events from the configuration object (e.g., Succeeded, Failed)
impl Dispatch<zwlr_output_configuration_v1::ZwlrOutputConfigurationV1, ()> for WlDelegate {
    fn event(
        _state: &mut Self,
        config: &zwlr_output_configuration_v1::ZwlrOutputConfigurationV1,
        event: zwlr_output_configuration_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
        trace!("zwlr_output_configuration_v1 event: {:?}", event);
        // When the config is applied, it's done, so we destroy it.
        match event {
            zwlr_output_configuration_v1::Event::Succeeded => {
                debug!("Output configuration applied successfully.");
                config.destroy();
            }
            zwlr_output_configuration_v1::Event::Failed => {
                error!("Failed to apply output configuration.");
                config.destroy();
            }
            zwlr_output_configuration_v1::Event::Cancelled => {
                warn!("Output configuration cancelled.");
                config.destroy();
            }
            _ => {}
        }
    }
}


// Handles events from the configuration *head* object.
// This object has no events, but we provide an empty handler
// to prevent any future panics.
impl Dispatch<zwlr_output_configuration_head_v1::ZwlrOutputConfigurationHeadV1, ()> for WlDelegate {
    fn event(
        _state: &mut Self,
        _config_head: &zwlr_output_configuration_head_v1::ZwlrOutputConfigurationHeadV1,
        event: zwlr_output_configuration_head_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
        trace!("zwlr_output_configuration_head_v1 event: {:?}", event);
    }
}
