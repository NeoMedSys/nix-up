// === ./programs/clammy/src/actions/lock.rs ===
//! Spawns the screen locker process.

use crate::config;
use log::{debug, error, info};
use std::process::{Command, Stdio};

pub fn request_lock() {
    info!("Executing lock command...");
    
    // We need to check if a lock is already running
    // For now, we'll just spawn.
    // TODO: Add a check to see if swaylock is already running
    
    let args = &config::LOCK_COMMAND[1..];
    let cmd = config::LOCK_COMMAND[0];

    debug!("Running lock command: {} {}", cmd, args.join(" "));

    match Command::new(cmd)
        .args(args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(mut child) => {
            debug!("Lock process spawned with PID: {}", child.id());
            // We detach the child. We don't wait for it.
            std::thread::spawn(move || {
                match child.wait() {
                    Ok(status) => debug!("Lock process exited with status: {}", status),
                    Err(e) => error!("Failed to wait for lock process: {}", e),
                }
            });
        }
        Err(e) => {
            error!(
                "Failed to spawn lock command '{}': {}. Is it in $PATH?",
                cmd, e
            );
        }
    }
}
