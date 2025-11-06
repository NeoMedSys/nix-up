use crate::config;
use log::{debug, error, info};
use std::process::{Command, Stdio};

pub fn request_lock() -> anyhow::Result<()> {
    info!("Executing lock command...");
    
    let args = &config::LOCK_COMMAND[1..];
    let cmd = config::LOCK_COMMAND[0];
    
    // Find the full path to the command by searching PATH
    let cmd_path = if let Ok(path_env) = std::env::var("PATH") {
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
        None
    };

    let cmd_to_run = cmd_path.as_deref().unwrap_or(cmd);
    debug!("Running lock command: {} {}", cmd_to_run, args.join(" "));

    match Command::new(cmd_to_run)
        .args(args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(mut child) => {
            debug!("Lock process spawned with PID: {}", child.id());
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
    Ok(())
}
