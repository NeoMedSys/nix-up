use crate::state::{Monitor, State};
use crate::wayland_manager::WlDelegate;
use anyhow::{anyhow, Result};
use log::{debug, info, error};
use niri_ipc::socket::Socket;
use niri_ipc::{Request, Response};
use wayland_client::QueueHandle;

pub fn dpms_off(_delegate: &WlDelegate, _qh: &QueueHandle<WlDelegate>) -> Result<()> {
	info!("DPMS: Turning all monitors off");
	crate::actions::dpms::dpms_off()
}

pub fn dpms_on(_delegate: &WlDelegate, _qh: &QueueHandle<WlDelegate>) -> Result<()> {
	info!("DPMS: Turning all monitors on");
	crate::actions::dpms::dpms_on()
}

pub fn configure_clamshell(state: &State, _delegate: &WlDelegate, _qh: &QueueHandle<WlDelegate>) -> Result<()> {
	info!("configure_clamshell called");
	let result = crate::actions::clamshell::apply_clamshell_config(state);
	if let Err(ref e) = result {
		error!("configure_clamshell failed: {}", e);
	}
	result
}

pub fn configure_lid_open(state: &State, _delegate: &WlDelegate, _qh: &QueueHandle<WlDelegate>) -> Result<()> {
	info!("configure_lid_open called");
	let result = crate::actions::lid_open::apply_lid_open_config(state);
	if let Err(ref e) = result {
		error!("configure_lid_open failed: {}", e);
	}
	result
}

pub fn scan_outputs(state_mutex: &crate::state::SharedState) -> Result<()> {
	debug!("Niri Native: Scanning outputs via IPC socket...");

	let mut socket = Socket::connect().map_err(|e| anyhow!("IPC Connect failed: {}", e))?;
	let reply = socket.send(Request::Outputs)?;
	let response = reply.map_err(|e| anyhow!("niri error: {}", e))?;

	if let Response::Outputs(outputs) = response {
		let mut externals = Vec::new();
		let mut edp = None;

		for (name, output) in outputs {
			let is_active = output.logical.is_some();
			let width = output.logical.as_ref().map(|l| l.width as i32).unwrap_or(0);
			let monitor = Monitor {
				name: name.clone(),
				width,
				active: is_active,
			};
			debug!("Found output: {} (active: {}, width: {})", name, is_active, width);

			if name.starts_with("eDP") || name.starts_with("LVDS") {
				edp = Some(monitor);
			} else {
				externals.push(monitor);
			}
		}

		let has_externals = !externals.is_empty();

		{
			let mut guard = state_mutex.lock().unwrap();
			guard.update_monitors(edp.clone(), externals.clone());
		}

		// Write dock state for PAM conditional fingerprint auth
		State::write_dock_state(has_externals);

		info!("Scan complete: eDP={:?}, {} external(s): {:?}",
			edp.as_ref().map(|m| &m.name),
			externals.len(),
			externals.iter().map(|m| &m.name).collect::<Vec<_>>());
	}

	Ok(())
}
