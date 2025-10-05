use anyhow::{Context, Result};
use clap::Parser;
use log::{debug, error, info, warn};
use std::process::{Command, Stdio};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;
use swayipc::{Connection, Event, EventType};

/// Clammy - Clamshell mode daemon for Sway
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
	external_monitors: Vec<String>,
	edp_name: Option<String>,
}

impl State {
	fn new() -> Self {
		Self {
			lid_closed: false,
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

/// Start swayidle
fn start_swayidle() -> Result<()> {
	info!("Starting swayidle...");

	let lock_cmd = r#"swaylock -f \
		--screenshots \
		--clock \
		--indicator \
		--indicator-radius 120 \
		--indicator-thickness 8 \
		--effect-blur 7x5 \
		--effect-vignette 0.5:0.5 \
		--ring-color e94560 \
		--key-hl-color 0f3460 \
		--line-color 00000000 \
		--inside-color 1a1a2e88 \
		--separator-color 00000000 \
		--grace 3 \
		--fade-in 0.1"#;

	Command::new("swayidle")
		.arg("-w")
		.arg("timeout")
		.arg("300")
		.arg(format!("{} -f -c 000000", lock_cmd))
		.arg("timeout")
		.arg("600")
		.arg("swaymsg \"output * power off\"")
		.arg("resume")
		.arg("swaymsg \"output * power on\"")
		.arg("before-sleep")
		.arg(format!("{} -f -c 000000", lock_cmd))
		.stdout(Stdio::null())
		.stderr(Stdio::null())
		.spawn()
		.context("Failed to spawn swayidle")?;

	Ok(())
}

/// Stop swayidle
fn stop_swayidle() -> Result<()> {
	info!("Stopping swayidle...");
	let _ = Command::new("pkill").arg("swayidle").status();
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
		x_offset += 1920; // TODO: Get actual monitor width
	}

	// Restart waybar
	debug!("Restarting waybar...");
	let _ = Command::new("pkill").arg("waybar").status();
	run_swaymsg(&["exec", "waybar"])?;

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
		x_offset += 1920; // TODO: Get actual eDP width
	}

	// Position external monitors after eDP
	for monitor in &state.external_monitors {
		debug!("Positioning monitor {} at x={}", monitor, x_offset);
		run_swaymsg(&["output", monitor, "pos", &x_offset.to_string(), "0"])?;
		x_offset += 1920; // TODO: Get actual monitor width
	}

	// Restart waybar
	debug!("Restarting waybar...");
	let _ = Command::new("pkill").arg("waybar").status();
	run_swaymsg(&["exec", "waybar"])?;

	info!("Lid open mode configured");
	Ok(())
}

/// Handle state change and take appropriate action
fn handle_state_change(state: &State) -> Result<()> {
	info!(
		"State: lid_closed={}, externals={}, edp={:?}",
		state.lid_closed,
		state.external_monitors.len(),
		state.edp_name
	);

	if state.lid_closed {
		// Lid is closed
		stop_swayidle()?;

		if state.has_externals() {
			// Clamshell mode
			configure_clamshell(state)?;
		} else {
			// No externals - suspend after delay
			info!("No external monitors, suspending in 3 seconds...");
			thread::sleep(Duration::from_secs(3));

			Command::new("systemctl")
				.arg("suspend")
				.status()
				.context("Failed to suspend")?;
		}
	} else {
		// Lid is open
		configure_lid_open(state)?;
		start_swayidle()?;
	}

	Ok(())
}

/// Listen for Sway output events
fn listen_output_events(state: Arc<Mutex<State>>) -> Result<()> {
	info!("Starting Sway output listener...");

	let connection = Connection::new()
		.context("Failed to connect to Sway")?;

	for event in connection.subscribe([EventType::Output])? {
		match event? {
			Event::Output(_) => {
				debug!("Output change detected");

				// Refresh output list
				let (edp, externals) = get_outputs()?;

				let mut state = state.lock().unwrap();
				let old_externals = state.external_monitors.clone();

				state.edp_name = edp;
				state.external_monitors = externals.clone();

				// Only reconfigure if externals changed AND lid is closed
				if old_externals != externals && state.lid_closed {
					info!("External monitors changed: {:?} -> {:?}", old_externals, externals);

					// If lid closed and all externals gone - suspend after delay
					if !state.has_externals() {
						info!("All externals disconnected while lid closed, suspending in 5 seconds...");
						drop(state); // Release lock before sleeping

						thread::sleep(Duration::from_secs(5));

						Command::new("systemctl")
							.arg("suspend")
							.status()
							.context("Failed to suspend")?;
					} else {
						// Reconfigure clamshell layout
						if let Err(e) = handle_state_change(&state) {
							error!("Failed to handle output change: {}", e);
						}
					}
				}
			}
			_ => {}
		}
	}

	Ok(())
}

fn main() -> Result<()> {
	let args = Args::parse();

	// Initialize logger
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

	// Wait for Sway socket to be available (retry for up to 10 seconds)
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
		lid_closed: false, // Assume lid open on start
		external_monitors: externals,
		edp_name: edp,
	}));

	// Start swayidle initially (assuming lid open)
	start_swayidle()?;

	info!("Clammy initialized, starting event listeners...");

	// Set up signal handlers for lid events (sent by Sway bindswitch)
	let state_sigusr1 = state.clone();
	let state_sigusr2 = state.clone();

	unsafe {
		signal_hook::low_level::register(signal_hook::consts::SIGUSR1, move || {
			info!("Received SIGUSR1 - lid closed");
			let mut state = state_sigusr1.lock().unwrap();
			state.lid_closed = true;
			
			// Refresh monitors
			if let Ok((edp, externals)) = get_outputs() {
				state.edp_name = edp;
				state.external_monitors = externals;
			}

			if let Err(e) = handle_state_change(&state) {
				error!("Failed to handle lid close: {}", e);
			}
		})?;

		signal_hook::low_level::register(signal_hook::consts::SIGUSR2, move || {
			info!("Received SIGUSR2 - lid opened");
			let mut state = state_sigusr2.lock().unwrap();
			state.lid_closed = false;

			// Refresh monitors
			if let Ok((edp, externals)) = get_outputs() {
				state.edp_name = edp;
				state.external_monitors = externals;
			}

			if let Err(e) = handle_state_change(&state) {
				error!("Failed to handle lid open: {}", e);
			}
		})?;
	}

	// Spawn output event listener
	let state_output = state.clone();
	let output_thread = thread::spawn(move || {
		if let Err(e) = listen_output_events(state_output) {
			error!("Output event listener failed: {}", e);
		}
	});

	// Keep main thread alive
	output_thread.join().unwrap();

	Ok(())
}
