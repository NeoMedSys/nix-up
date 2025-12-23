use crate::config;
use log::{debug, error, info, warn};
use std::process::{Command, Stdio};

pub fn request_lock() -> anyhow::Result<()> {
    info!("Executing lock command...");
    let args = &config::LOCK_COMMAND[1..];
    let cmd = config::LOCK_COMMAND[0];

    // Find the full path to the command by searching PATH
    let cmd_path = if let Ok(path_env) = std::env::var("PATH") {
        debug!("PATH: {}", path_env);
        let mut found = None;
        for dir in path_env.split(':') {
            let full_path = format!("{}/{}", dir, cmd);
            if std::path::Path::new(&full_path).exists() {
                found = Some(full_path);
                break;
            }
        }
        found
    } else {
        warn!("PATH environment variable not set!");
        None
    };

    let cmd_to_run = cmd_path.as_deref().unwrap_or(cmd);
    debug!("Running lock command: {} {}", cmd_to_run, args.join(" "));

    // Log environment variables we're passing
    debug!("Environment variables:");
    if let Ok(val) = std::env::var("WAYLAND_DISPLAY") {
        debug!("  WAYLAND_DISPLAY: {}", val);
    } else {
        warn!("  WAYLAND_DISPLAY: not set!");
    }
    if let Ok(val) = std::env::var("XDG_RUNTIME_DIR") {
        debug!("  XDG_RUNTIME_DIR: {}", val);
    } else {
        warn!("  XDG_RUNTIME_DIR: not set!");
    }
    if let Ok(val) = std::env::var("NIRI_SOCKET") {
        debug!("  NIRI_SOCKET: {}", val);
    } else {
        warn!("  NIRI_SOCKET: not set!");
    }
    if let Ok(val) = std::env::var("DBUS_SESSION_BUS_ADDRESS") {
        debug!("  DBUS_SESSION_BUS_ADDRESS: {}", val);
    } else {
        warn!("  DBUS_SESSION_BUS_ADDRESS: not set!");
    }

    // Build and spawn the command with inherited environment
    // CAPTURE stdout and stderr so we can see what failed
    let spawn_result = {
        let mut cmd = Command::new(cmd_to_run);
        cmd.args(args)
            .stdout(Stdio::piped())  // CHANGED: Capture output
            .stderr(Stdio::piped());  // CHANGED: Capture errors

        // Pass critical environment variables for DMS IPC
        if let Ok(val) = std::env::var("WAYLAND_DISPLAY") {
            cmd.env("WAYLAND_DISPLAY", val);
        }
        if let Ok(val) = std::env::var("XDG_RUNTIME_DIR") {
            cmd.env("XDG_RUNTIME_DIR", val);
        }
        if let Ok(val) = std::env::var("NIRI_SOCKET") {
            cmd.env("NIRI_SOCKET", val);
        }
        if let Ok(val) = std::env::var("DBUS_SESSION_BUS_ADDRESS") {
            cmd.env("DBUS_SESSION_BUS_ADDRESS", val);
        }
        if let Ok(val) = std::env::var("PATH") {
            cmd.env("PATH", val);
        }

        cmd.spawn()
    };

    match spawn_result {
        Ok(mut child) => {
            debug!("Lock process spawned with PID: {}", child.id());
            std::thread::spawn(move || {
                match child.wait_with_output() {
                    Ok(output) => {
                        debug!("Lock process exited with status: {}", output.status);
                        
                        // Log stdout if there was any
                        if !output.stdout.is_empty() {
                            if let Ok(stdout) = String::from_utf8(output.stdout) {
                                info!("Lock stdout: {}", stdout.trim());
                            }
                        }
                        
                        // Log stderr if there was any
                        if !output.stderr.is_empty() {
                            if let Ok(stderr) = String::from_utf8(output.stderr) {
                                if output.status.success() {
                                    debug!("Lock stderr: {}", stderr.trim());
                                } else {
                                    error!("Lock command failed! stderr: {}", stderr.trim());
                                }
                            }
                        }
                        
                        if !output.status.success() {
                            error!("Lock command exited with non-zero status: {}", output.status);
                        }
                    }
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

    Ok(())
}
