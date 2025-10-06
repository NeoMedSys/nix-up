use anyhow::{Context, Result};
use clap::Parser;
use log::{debug, error, info, warn};
use std::process::{Command, Stdio};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;
use swayipc::{Connection, Event, EventType};

/// Clammy - Lid and display management for Sway
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Enable verbose logging
    #[arg(short, long)]
    verbose: bool,
}

/// System state tracker
#[derive(Debug, Clone)]
struct State {
    lid_closed: bool,
    displays_off: bool,
    external_monitors: Vec<String>,
    edp_name: Option<String>,
}

impl State {
    fn new() -> Self {
        Self {
            lid_closed: false,
            displays_off: false,
            external_monitors: Vec::new(),
            edp_name: None,
        }
    }

    fn has_externals(&self) -> bool {
        !self.external_monitors.is_empty()
    }
}

/// Execute swaymsg command
fn run_swaymsg(args: &[&str]) -> Result<()> {
    debug!("Running: swaymsg {}", args.join(" "));

    let output = Command::new("swaymsg")
        .args(args)
        .output()
        .context("Failed to execute swaymsg")?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        warn!("swaymsg failed: {}", stderr);
    }

    Ok(())
}

/// Get current outputs from Sway
fn get_outputs() -> Result<(Option<String>, Vec<String>)> {
    let mut connection = Connection::new()
        .context("Failed to connect to Sway")?;

    let outputs = connection
        .get_outputs()
        .context("Failed to get outputs")?;

    let mut edp_name = None;
    let mut externals = Vec::new();

    for output in outputs {
        if output.name.starts_with("eDP") {
            edp_name = Some(output.name);
        } else if output.active {
            externals.push(output.name);
        }
    }

    externals.sort();
    Ok((edp_name, externals))
}

fn lock_screen() -> Result<()> {
    info!("Locking screen...");
    
    // Use sway's $lock variable which already has all the visual settings
    run_swaymsg(&["exec", "$lock"])?;
    
    Ok(())
}

/// Turn displays off using DPMS
fn displays_off() -> Result<()> {
    info!("Turning displays off (DPMS)...");
    run_swaymsg(&["output", "*", "power", "off"])?;
    Ok(())
}

/// Turn displays on using DPMS
fn displays_on() -> Result<()> {
    info!("Turning displays on (DPMS)...");
    run_swaymsg(&["output", "*", "power", "on"])?;
    Ok(())
}

/// Configure monitors for clamshell mode (lid closed with externals)
fn configure_clamshell(state: &State) -> Result<()> {
    info!("Configuring clamshell mode...");

    // Disable eDP
    if let Some(edp) = &state.edp_name {
        debug!("Disabling eDP: {}", edp);
        run_swaymsg(&["output", edp, "disable"])?;
    }

    // Arrange external monitors left-to-right
    let mut x_offset = 0;
    for monitor in &state.external_monitors {
        debug!("Positioning monitor {} at x={}", monitor, x_offset);
        run_swaymsg(&["output", monitor, "pos", &x_offset.to_string(), "0"])?;
        x_offset += 1920;
    }

    info!("Clamshell mode configured");
    Ok(())
}

/// Configure monitors for lid open (eDP leftmost)
fn configure_lid_open(state: &State) -> Result<()> {
    info!("Configuring lid open mode...");

    let mut x_offset = 0;

    // Enable and position eDP leftmost
    if let Some(edp) = &state.edp_name {
        debug!("Enabling eDP at x=0: {}", edp);
        run_swaymsg(&["output", edp, "enable"])?;
        run_swaymsg(&["output", edp, "pos", "0", "0"])?;
        x_offset += 1920;
    }

    // Position external monitors after eDP
    for monitor in &state.external_monitors {
        debug!("Positioning monitor {} at x={}", monitor, x_offset);
        run_swaymsg(&["output", monitor, "pos", &x_offset.to_string(), "0"])?;
        x_offset += 1920;
    }

    info!("Lid open mode configured");
    Ok(())
}

/// Handle lid close
fn handle_lid_close(state: &mut State) -> Result<()> {
    info!("Lid closed");

    lock_screen()?;

    // Configure displays
    if state.has_externals() {
        configure_clamshell(state)?;
    }

    Ok(())
}

/// Handle lid open
fn handle_lid_open(state: &mut State) -> Result<()> {
    info!("Lid opened");
    displays_on()?;
    configure_lid_open(state)?;
    Ok(())
}

fn listen_sway_events(state: Arc<Mutex<State>>) -> Result<()> {
    info!("Starting Sway event listener...");

    loop {
        let connection = match Connection::new() {
            Ok(c) => c,
            Err(e) => {
                error!("Failed to connect to Sway: {}", e);
                thread::sleep(Duration::from_secs(5));
                continue;
            }
        };

        let events = match connection.subscribe([EventType::Output]) {
            Ok(e) => e,
            Err(e) => {
                error!("Failed to subscribe to events: {}", e);
                thread::sleep(Duration::from_secs(5));
                continue;
            }
        };

        for event in events {
            let event = match event {
                Ok(e) => e,
                Err(e) => {
                    warn!("Event error: {}, reconnecting...", e);
                    break;
                }
            };

            if let Event::Output(_) = event {
                debug!("Output change detected");

                if let Ok((edp, externals)) = get_outputs() {
                    let mut state = state.lock().unwrap();
                    let old_externals = state.external_monitors.clone();

                    state.edp_name = edp;
                    state.external_monitors = externals.clone();

                    if old_externals != externals && state.lid_closed {
                        info!("External monitors changed while lid closed: {:?} -> {:?}", old_externals, externals);

                        if state.has_externals() {
                            if let Err(e) = configure_clamshell(&state) {
                                error!("Failed to configure clamshell: {}", e);
                            }
                        } else {
                            info!("No externals while lid closed, re-enabling eDP");
                            if let Some(edp) = &state.edp_name {
                                if let Err(e) = run_swaymsg(&["output", edp, "enable"]) {
                                    error!("Failed to enable eDP: {}", e);
                                }
                            }
                        }
                    }
                }
            }
        }

        warn!("Event stream ended, reconnecting in 5 seconds...");
        thread::sleep(Duration::from_secs(5));
    }
}

fn main() -> Result<()> {
    let args = Args::parse();

    if args.verbose {
        env_logger::Builder::from_default_env()
            .filter_level(log::LevelFilter::Debug)
            .init();
    } else {
        env_logger::Builder::from_default_env()
            .filter_level(log::LevelFilter::Info)
            .init();
    }

    info!("Clammy daemon starting...");

    let mut retries = 0;
    let max_retries = 10;

    let (edp, externals) = loop {
        match get_outputs() {
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
    };

    let state = Arc::new(Mutex::new(State {
        lid_closed: false,
        displays_off: false,
        external_monitors: externals,
        edp_name: edp,
    }));

    info!("Clammy initialized");

    let state_sigusr1 = state.clone();
    let state_sigusr2 = state.clone();

    unsafe {
        signal_hook::low_level::register(signal_hook::consts::SIGUSR1, move || {
            let mut state = state_sigusr1.lock().unwrap();
            state.lid_closed = true;

            if let Ok((edp, externals)) = get_outputs() {
                state.edp_name = edp;
                state.external_monitors = externals;
            }

            if let Err(e) = handle_lid_close(&mut state) {
                error!("Failed to handle lid close: {}", e);
            }
        })?;

        signal_hook::low_level::register(signal_hook::consts::SIGUSR2, move || {
            let mut state = state_sigusr2.lock().unwrap();
            state.lid_closed = false;

            if let Ok((edp, externals)) = get_outputs() {
                state.edp_name = edp;
                state.external_monitors = externals;
            }

            if let Err(e) = handle_lid_open(&mut state) {
                error!("Failed to handle lid open: {}", e);
            }
        })?;
    }

    let state_output = state.clone();
    thread::spawn(move || {
        if let Err(e) = listen_sway_events(state_output) {
            error!("Output event listener failed: {}", e);
        }
    });

    loop {
        thread::sleep(Duration::from_secs(60));
    }
}
