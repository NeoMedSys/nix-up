// === ./programs/clammy/src/state.rs ===
//! System state tracker
use log::debug;
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
}

pub type SharedState = Arc<Mutex<State>>;
