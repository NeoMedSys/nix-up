//! System state tracker
use log::{debug, error};
use std::sync::{Arc, Mutex};

// NOTE: This Monitor struct is now generic.
// It will be populated by wayland_output.rs
#[derive(Debug, Clone, Default, PartialEq)]
pub struct Monitor {
	pub name: String,
	pub width: i32,
	pub active: bool,
}

#[derive(Debug, Clone, Default, PartialEq)]
pub struct State {
	pub lid_closed: bool,
	pub displays_off: bool,
	pub external_monitors: Vec<Monitor>,
	pub edp_name: Option<Monitor>,
}

impl State {
	pub fn new() -> Self {
		Self::default()
	}

	pub fn has_externals(&self) -> bool {
		!self.external_monitors.is_empty()
	}

	pub fn update_monitors(&mut self, edp: Option<Monitor>, externals: Vec<Monitor>) {
		debug!("State updating monitors: eDP={:?}, externals={:?}", edp, externals);
		self.edp_name = edp;
		self.external_monitors = externals;
	}

	/// Write dock state to /run/clammy/docked for PAM conditional fingerprint auth.
	/// "1" = docked (externals present), "0" = undocked (laptop only).
	pub fn write_dock_state(docked: bool) {
		let val = if docked { "1" } else { "0" };
		if let Err(e) = std::fs::write("/run/clammy/docked", val) {
			error!("Failed to write /run/clammy/docked: {}", e);
		} else {
			debug!("Wrote /run/clammy/docked = {}", val);
		}
	}
}

pub type SharedState = Arc<Mutex<State>>;
