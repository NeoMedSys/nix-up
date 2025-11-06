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
        .and_then(|info| info.borrow().preferred_mode.clone())
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
                        if info.name.starts_with("eDP") {
                            edp = Some(monitor);
                        } else {
                            externals.push(monitor);
                        }
                    } else {
                        warn!("Head {} is active but has no modes?", info.name);
                    }
                }

                externals.sort_by(|a, b| a.name.cmp(&b.name));
                info!("Parse complete: eDP={:?}, externals={:?}", edp, externals);

                // Update the global state
                {
                    let mut shared_state = state.state.lock().unwrap();
                    shared_state.edp_name = edp;
                    shared_state.external_monitors = externals;
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
                // Ensure we have an entry for this head
                if !state.temp_heads.contains_key(head) {
                    let head_info = Rc::new(RefCell::new(HeadInfo::default()));
                    state.temp_heads.insert(head.clone(), head_info);
                }
                let info_rc = state.temp_heads.get(head).unwrap().clone();
                let mut info = info_rc.borrow_mut();
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
                // Mode events will be handled in the mode dispatch
            }
            zwlr_output_head_v1::Event::Finished => {
                trace!("DEBUG: Head {:?} finished (unplugged)", head.id());
                drop(info); // Release borrow before removing
                state.temp_heads.remove(head);
            }
            _ => {}
        }
    }
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
        let head_info = state.temp_heads.values().find(|info| {
            info.borrow().modes.iter().any(|m| m.wl_mode.as_ref() == Some(mode))
        }).cloned();

        if head_info.is_none() {
            // This is a new mode, find the head that just announced it
            // We'll add it on Finished event
            return;
        }

        let info_rc = head_info.unwrap();
        let mut info = info_rc.borrow_mut();

        // Find or create the ModeInfo for this mode
        let mut mode_info = info
            .modes
            .iter()
            .find(|m| m.wl_mode.as_ref() == Some(mode))
            .cloned()
            .unwrap_or_default();

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
                mode_info.wl_mode = Some(mode.clone());

                // Remove old entry if it exists
                info.modes.retain(|m| m.wl_mode.as_ref() != Some(mode));
                // Add the new/updated one
                info.modes.push(mode_info.clone());

                if mode_info.is_preferred {
                    info.preferred_mode = Some(mode_info);
                }
            }
            _ => {}
        }
    }
}

// No-op implementations for configuration objects
delegate_noop!(WlDelegate: zwlr_output_configuration_v1::ZwlrOutputConfigurationV1);
delegate_noop!(WlDelegate: zwlr_output_configuration_head_v1::ZwlrOutputConfigurationHeadV1);
