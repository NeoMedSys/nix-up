//! System state tracker
use anyhow::Result;
use log::debug;
use std::sync::{Arc, Mutex};

use crate::sway::{self, Monitor}; // Import the new Monitor struct

#[derive(Debug, Clone, Default, PartialEq)]
pub struct State {
    pub lid_closed: bool,
    pub displays_off: bool,
    pub external_monitors: Vec<Monitor>, // Was Vec<String>
    pub edp_name: Option<Monitor>,     // Was Option<String>
}

impl State {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn has_externals(&self) -> bool {
        !self.external_monitors.is_empty()
    }

    /// Rescans and updates the monitor state from Sway
    /// This is useful after a lid or monitor change
    pub fn refresh_outputs(&mut self) -> Result<()> {
        debug!("Refreshing output state from Sway...");
        match sway::get_outputs() {
            Ok((edp, externals)) => {
                debug!("Refreshed outputs: eDP={:?}, externals={:?}", edp, externals);
                self.edp_name = edp;
                self.external_monitors = externals;
                Ok(())
            }
            Err(e) => {
                log::error!("Failed to refresh outputs: {}", e);
                Err(e)
            }
        }
    }
}

// A type alias for our shared, thread-safe state
pub type SharedState = Arc<Mutex<State>>;

