//! Spawns and manages the swayidle process, reading its events.
use log::{debug, error, info, warn};
use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio, Child};
use std::thread;
use std::time::Duration;

use crate::config; // Import the new config
use crate::state::SharedState;
use crate::sway;

/// Spawns swayidle as a child process and listens for its events
fn spawn_swayidle() -> Option<Child> {
    info!("Spawning swayidle process...");

    // Use values from config.rs
    let idle_timeout_str = config::IDLE_TIMEOUT_S.to_string();
    let sleep_timeout_str = config::SLEEP_TIMEOUT_S.to_string();

    debug!(
        "swayidle cmd: timeout {} '{}' resume '{}' timeout {} '{}' resume '{}' before-sleep '{}'",
        idle_timeout_str,
        config::IDLE_EVENT_CMD,
        config::RESUME_EVENT_CMD,
        sleep_timeout_str,
        config::SLEEP_EVENT_CMD,
        config::RESUME_EVENT_CMD,
        config::SLEEP_EVENT_CMD
    );

    match Command::new("swayidle")
        .arg("-w") // -w flag makes it write events to stdout
        .arg("timeout")
        .arg(&idle_timeout_str)
        .arg(config::IDLE_EVENT_CMD)
        .arg("resume")
        .arg(config::RESUME_EVENT_CMD)
        .arg("timeout")
        .arg(&sleep_timeout_str)
        .arg(config::SLEEP_EVENT_CMD)
        .arg("resume") // Also send resume after sleep
        .arg(config::RESUME_EVENT_CMD)
        .arg("before-sleep") // Lock before suspend
        .arg(config::SLEEP_EVENT_CMD)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
    {
        Ok(child) => {
            info!("swayidle spawned with PID: {}", child.id());
            Some(child)
        }
        Err(e) => {
            error!("Failed to spawn swayidle: {}. Is it in $PATH?", e);
            None
        }
    }
}

/// Handles events from swayidle's stdout
fn handle_idle_event(event: &str, state: &SharedState) {
    let mut state = state.lock().unwrap();
    debug!("State lock acquired for idle event: '{}'", event);

    // Don't do anything if the lid is already closed
    if state.lid_closed {
        debug!("Idle event received, but lid is closed. Ignoring.");
        debug!("State lock released for idle event (ignored)");
        return;
    }
    
    // Match against the configured event commands
    match event {
        e if e == config::IDLE_EVENT_CMD => {
            info!("Swayidle: IDLE event received");
            if !state.displays_off {
                debug!("Displays were on, turning off for idle");
                if let Err(e) = sway::displays_off() {
                    error!("Failed to turn displays off: {}", e);
                }
                state.displays_off = true;
            } else {
                debug!("Displays already off, idle event ignored.");
            }
        }
        e if e == config::RESUME_EVENT_CMD => {
            info!("Swayidle: RESUME event received");
            if state.displays_off {
                debug!("Displays were off, turning on for resume");
                if let Err(e) = sway::displays_on() {
                    error!("Failed to turn displays on: {}", e);
                }
                state.displays_off = false;
            } else {
                debug!("Displays already on, resume event ignored.");
            }
        }
        e if e == config::SLEEP_EVENT_CMD => {
            info!("Swayidle: SLEEP event (or before-sleep) received");
            // We just lock. systemd-logind will handle the actual suspend.
            if let Err(e) = sway::lock_screen() {
                error!("Failed to lock screen for sleep: {}", e);
            }
        }
        _ => {
            warn!("Unknown swayidle event: {}", event);
        }
    }
    debug!("State lock released for idle event");
}

/// Main loop for the idle listener thread
pub fn listen_idle_events(state: SharedState) {
    info!("Starting swayidle event listener...");
    loop {
        let mut child = match spawn_swayidle() {
            Some(c) => c,
            None => {
                // Failed to spawn, retry after a delay
                error!("swayidle failed to spawn, retrying in 10s...");
                thread::sleep(Duration::from_secs(10));
                continue;
            }
        };

        let stdout = child.stdout.take().expect("Failed to open swayidle stdout");
        let reader = BufReader::new(stdout);
        debug!("Reading stdout from swayidle...");

        for line in reader.lines() {
            match line {
                Ok(event) => {
                    handle_idle_event(&event, &state);
                }
                Err(e) => {
                    error!("Failed to read from swayidle: {}", e);
                    break;
                }
            }
        }
        
        // If the loop exits, swayidle has crashed.
        warn!("swayidle process exited. Restarting in 5 seconds...");
        if let Err(e) = child.kill() {
             warn!("Failed to kill defunct swayidle process (it may have already exited): {}", e);
        }
        // Wait for the process to be fully reaped
        match child.wait() {
            Ok(status) => debug!("swayidle child exited with status: {}", status),
            Err(e) => error!("Failed to wait for swayidle child: {}", e),
        }
        
        thread::sleep(Duration::from_secs(5));
    }
}
