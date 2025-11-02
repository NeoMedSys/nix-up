//! The main entry point for the Clammy daemon
use anyhow::{Context, Result};
use clap::Parser;
use log::{debug, error, info, warn};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;
use zbus::{proxy, Connection};
use futures_util::stream::StreamExt;

mod config; 
mod state;
mod sway;
mod idle;

use state::{SharedState, State};

/// Clammy - Lid and display management for Sway
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Enable verbose logging
    #[arg(short, long)]
    verbose: bool,
}

// Create a D-Bus proxy for logind
#[proxy(
    interface = "org.freedesktop.login1.Manager",
    default_service = "org.freedesktop.login1",
    default_path = "/org/freedesktop/login1"
)]
trait LoginManager {
    /// LidClosed property
    #[zbus(property)]
    fn lid_closed(&self) -> zbus::Result<bool>;

    /// Suspend method
    fn suspend(&self, interactive: bool) -> zbus::Result<()>;

    // We can also listen for signals like PrepareForSleep
}

/// Initializes logging based on args
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

/// The main async entry point
#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    setup_logging(&args);

    info!("Clammy daemon starting...");

    // 1. Initial connection to Sway (with retry loop, preserving original logic)
    let (edp, externals) = {
        let mut retries = 0;
        let max_retries = 10;
        loop {
            match sway::get_outputs() {
                Ok(result) => {
                    info!("Connected to Sway successfully");
                    break result;
                }
                Err(e) => {
                    if retries < max_retries {
                        warn!("Failed to connect to Sway (attempt {}/{}): {}", retries + 1, max_retries, e);
                        retries += 1;
                        thread::sleep(Duration::from_secs(1));
                    } else {
                        error!("Failed to connect to Sway after {} attempts", max_retries);
                        return Err(e);
                    }
                }
            }
        }
    };

    debug!("Initial state: eDP={:?}, externals={:?}", edp, externals);

    // 2. Connect to D-Bus (system bus)
    let dbus_conn = Connection::system()
        .await
        .context("Failed to connect to D-Bus system bus")?;

    // Create a proxy for logind
    let login_proxy = LoginManagerProxy::new(&dbus_conn)
        .await
        .context("Failed to create logind proxy")?;

    info!("Connected to D-Bus and logind");

    // 3. Get initial lid state
    let initial_lid_closed = login_proxy
        .lid_closed()
        .await
        .context("Failed to get initial lid state")?;

    info!("Initial lid state: {}", if initial_lid_closed { "CLOSED" } else { "OPEN" });

    // 4. Create the shared state
    let state = Arc::new(Mutex::new(State {
        lid_closed: initial_lid_closed,
        displays_off: false,
        external_monitors: externals,
        edp_name: edp,
    }));

    // 5. Spawn the Sway event listener in a separate thread
    let sway_state = state.clone();
    thread::spawn(move || {
        if let Err(e) = sway::listen_sway_events(sway_state) {
            error!("Sway event listener failed: {}", e);
        }
    });
    info!("Sway IPC event listener started");

    // 6. Spawn the Idle listener in a separate thread
    let idle_state = state.clone();
    thread::spawn(move || {
        idle::listen_idle_events(idle_state);
    });
    info!("Swayidle event listener started");


    // 7. Set up D-Bus property change listener for the lid
    let mut lid_stream = login_proxy
        .receive_lid_closed_changed()
        .await;

    info!("Listening for logind lid events...");

    // 8. Run the main D-Bus event loop
    while let Some(signal) = lid_stream.next().await {
        let is_closed = signal.get().await?;
        info!("D-Bus signal: Lid state changed to: {}", if is_closed { "CLOSED" } else { "OPEN" });

        let has_externals = {
            let mut state = state.lock().unwrap();
            debug!("State lock acquired for lid event");

            // Refresh monitor list, as monitors might have changed
            if let Err(e) = state.refresh_outputs() {
                 error!("Failed to refresh outputs on lid event: {}", e);
            }

            if is_closed {
                if let Err(e) = sway::handle_lid_close(&mut state) {
                    error!("Failed to handle lid close: {}", e);
                }
            } else {
                if let Err(e) = sway::handle_lid_open(&mut state) {
                    error!("Failed to handle lid open: {}", e);
                }
            }
            
            // Get the value *before* the lock is released
            let current_has_externals = state.has_externals();
            debug!("State lock released for lid event");
            current_has_externals // Return the boolean value
        }; 

        if is_closed && !has_externals {
            info!(
                "Lid closed with no external monitors. Scheduling suspend in {}s.",
                config::LID_CLOSE_SUSPEND_DELAY_S
            );

            // Clone Arcs to move into the async task
            let state_clone = state.clone();
            let proxy_clone = login_proxy.clone();

            tokio::spawn(async move {
                tokio::time::sleep(Duration::from_secs(config::LID_CLOSE_SUSPEND_DELAY_S)).await;

                // Re-check state before suspending
                let (lid_closed, has_externals) = {
                    let state = state_clone.lock().unwrap();
                    debug!("Suspend task: checking state...");
                    (state.lid_closed, state.has_externals())
                };

                if lid_closed && !has_externals {
                    info!("Suspend task: Lid still closed with no externals. Suspending now.");
                    if let Err(e) = proxy_clone.suspend(false).await {
                        error!("Failed to send suspend request to logind: {}", e);
                    } else {
                        info!("Suspend request sent successfully to logind.");
                    }
                } else {
                    info!("Suspend task: Aborting suspend. Lid was opened or monitor was plugged in.");
                }
            });
        }
    }

    warn!("D-Bus event stream ended. This should not happen.");
    Ok(())
}
