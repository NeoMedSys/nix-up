use anyhow::{Context, Result};
use clap::Parser;
use futures_util::stream::StreamExt;
use log::{debug, error, info};
use std::sync::{mpsc, Arc, Mutex};
use std::thread;
use std::time::Duration;
use zbus::{proxy, Connection};
use crate::commands::{DbusCommand, WaylandCommand};
use tokio::sync::mpsc as tokio_mpsc;

mod commands;
mod config;
mod state;
mod actions;
mod wayland_idle;
mod wayland_manager;
mod wayland_output;

use state::State;

/// Clammy - Lid and display management for Sway
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Enable verbose logging
    #[arg(short, long)]
    verbose: bool,
}

// D-Bus proxy for logind (unchanged)
#[proxy(
    interface = "org.freedesktop.login1.Manager",
    default_service = "org.freedesktop.login1",
    default_path = "/org/freedesktop/login1"
)]
trait LoginManager {
    #[zbus(property)]
    fn lid_closed(&self) -> zbus::Result<bool>;
    fn suspend(&self, interactive: bool) -> zbus::Result<()>;
}

fn setup_logging(args: &Args) {
    let level = if args.verbose {
        log::LevelFilter::Debug
    } else {
        log::LevelFilter::Info
    };
    env_logger::Builder::from_default_env()
        .filter_level(level)
        .init();
    debug!("Verbose logging enabled");
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    setup_logging(&args);

    info!("Clammy daemon starting...");

    // 1. Connect to D-Bus (system bus)
    let dbus_conn = Connection::system()
        .await
        .context("Failed to connect to D-Bus system bus")?;

    let login_proxy = LoginManagerProxy::new(&dbus_conn)
        .await
        .context("Failed to create logind proxy")?;
    info!("Connected to D-Bus and logind");

    // 2. Get initial lid state
    let initial_lid_closed = login_proxy
        .lid_closed()
        .await
        .context("Failed to get initial lid state")?;
    info!("Initial lid state: {}", if initial_lid_closed { "CLOSED" } else { "OPEN" });

    // 3. Create the shared state
    let state = Arc::new(Mutex::new(State {
        lid_closed: initial_lid_closed,
        displays_off: false,
        external_monitors: Vec::new(), // Wayland thread will populate this
        edp_name: None,                // Wayland thread will populate this
    }));

    // 4. Create the MPSC channel
    // Channel 1: Async -> Sync (for lid events)
    let (wayland_tx, wayland_rx) = mpsc::channel::<WaylandCommand>();
    // Channel 2: Sync -> Async (for suspend requests)
    let (suspend_tx, mut suspend_rx) = tokio_mpsc::channel::<DbusCommand>(10);

    // 5. Spawn the Wayland event listener in a separate thread
    let wayland_state = state.clone();
    thread::spawn(move || {
        info!("Wayland worker thread started");
        if let Err(e) = wayland_manager::run_wayland_listener(
            wayland_state, 
            wayland_rx, // Pass RX for lid commands
            suspend_tx,  // Pass TX for suspend commands
        ) {
            error!("Wayland event listener failed: {}", e);
        }
    });
    info!("Wayland event listener spawned");

    // 6. Set up D-Bus property change listener for the lid
    let mut lid_stream = login_proxy.receive_lid_closed_changed().await;
    info!("Listening for logind lid events...");
    
    // 7. Run the main D-Bus event loop with tokio::select!
    loop {
        tokio::select! {
            // --- Event 1: Lid state changed ---
            Some(signal) = lid_stream.next() => {
                let is_closed = signal.get().await?;
                info!("D-Bus signal: Lid state changed to: {}", if is_closed { "CLOSED" } else { "OPEN" });
                tokio::time::sleep(Duration::from_millis(500)).await;

                if is_closed {
                    wayland_tx.send(WaylandCommand::LidClosed)?;
                } else {
                    wayland_tx.send(WaylandCommand::LidOpened)?;
                }

                // Suspend Logic (unchanged)
                let has_externals = state.lock().unwrap().has_externals();
                if is_closed && !has_externals {
                    info!("Lid closed, no externals. Scheduling suspend.");
                        let login_proxy_clone = login_proxy.clone();
                        let state_clone = state.clone();
                        let delay = Duration::from_secs(config::LID_CLOSE_SUSPEND_DELAY_S);

                        tokio::spawn(async move {
                            tokio::time::sleep(delay).await;
                            let lid_still_closed = state_clone.lock().unwrap().lid_closed;

                            if lid_still_closed {
                                info!("Lid closed delay expired, suspending now.");
                                if let Err(e) = login_proxy_clone.suspend(false).await {
                                    error!("Failed to suspend: {}", e);
                                }
                            } else {
                                info!("Suspend aborted: lid was opened during delay.");
                            }
                        });
                    }
            }

            // --- Event 2: Suspend request from Wayland thread ---
            Some(cmd) = suspend_rx.recv() => {
                match cmd {
                    DbusCommand::RequestSuspend => {
                        info!("Received RequestSuspend from idle timer.");
                        // Only suspend if lid is open (lid-closed suspend
                        // is handled by the logic above)
                        let (lid_closed, displays_off) = {
                            let s = state.lock().unwrap();
                            (s.lid_closed, s.displays_off)
                        };

                        if !lid_closed && displays_off {
                             info!("Idle suspend: Lid is open and displays are off. Suspending now.");
                             if let Err(e) = login_proxy.suspend(false).await {
                                 error!("Failed to send suspend request to logind: {}", e);
                             }
                        } else {
                             info!("Idle suspend: Aborting, state changed (Lid closed or displays on).");
                        }
                    }

                    DbusCommand::RequestLidClosedSuspend => {
                        info!("Received RequestLidClosedSuspend from Wayland thread.");
                        let has_externals = state.lock().unwrap().has_externals();
                        
                        if !has_externals {
                            info!("Lid closed, no externals. Scheduling suspend.");
                            let login_proxy_clone = login_proxy.clone();
                            let state_clone = state.clone();
                            let delay = Duration::from_secs(config::LID_CLOSE_SUSPEND_DELAY_S);

                            tokio::spawn(async move {
                                tokio::time::sleep(delay).await;
                                let lid_still_closed = state_clone.lock().unwrap().lid_closed;

                                if lid_still_closed {
                                    info!("Lid closed delay expired, suspending now.");
                                    if let Err(e) = login_proxy_clone.suspend(false).await {
                                        error!("Failed to suspend: {}", e);
                                    }
                                } else {
                                    info!("Suspend aborted: lid was opened during delay.");
                                }
                            });
                        }
                    }
                }
            }
        }
    }
    Ok(())
}
