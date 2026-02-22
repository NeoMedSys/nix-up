use anyhow::Result;
use log::{error, info};
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::thread;
use std::time::Duration;

static ORIGINAL_BRIGHTNESS: OnceLock<Mutex<Option<u32>>> = OnceLock::new();
static DIM_CANCEL: OnceLock<Arc<AtomicBool>> = OnceLock::new();

fn brightness_store() -> &'static Mutex<Option<u32>> {
	ORIGINAL_BRIGHTNESS.get_or_init(|| Mutex::new(None))
}

fn cancel_flag() -> &'static Arc<AtomicBool> {
	DIM_CANCEL.get_or_init(|| Arc::new(AtomicBool::new(false)))
}

fn get_current_percent() -> Result<u32> {
	let cur = Command::new("brightnessctl").arg("get").output()?;
	let max = Command::new("brightnessctl").arg("max").output()?;
	let cur_val: f64 = String::from_utf8_lossy(&cur.stdout).trim().parse()?;
	let max_val: f64 = String::from_utf8_lossy(&max.stdout).trim().parse()?;
	Ok(((cur_val / max_val) * 100.0).round() as u32)
}

fn set_percent(percent: u32) {
	if let Err(e) = Command::new("brightnessctl")
		.args(["set", &format!("{}%", percent)])
		.output()
	{
		error!("brightnessctl set {}%: {}", percent, e);
	}
}

/// Start a gradual dim from current brightness to `target` over `duration_ms`.
/// Cancellable via resume/restore.
pub fn start_gradual_dim(target: u32, duration_ms: u64) -> Result<()> {
	let current = get_current_percent()?;
	let mut saved = brightness_store().lock().unwrap();
	if saved.is_none() {
		info!("Saved original brightness: {}%", current);
		*saved = Some(current);
	}
	drop(saved);

	if current <= target {
		return Ok(());
	}

	let flag = cancel_flag().clone();
	flag.store(false, Ordering::SeqCst);

	let steps = (current - target) as u64;
	let step_delay = Duration::from_millis(duration_ms / steps.max(1));

	thread::spawn(move || {
		for pct in (target..current).rev() {
			if flag.load(Ordering::SeqCst) {
				return;
			}
			set_percent(pct);
			thread::sleep(step_delay);
		}
	});

	info!("Gradual dim started: {}% -> {}% over {}ms", current, target, duration_ms);
	Ok(())
}

pub fn restore() -> Result<()> {
	cancel_flag().store(true, Ordering::SeqCst);
	let mut saved = brightness_store().lock().unwrap();
	if let Some(val) = saved.take() {
		set_percent(val);
		info!("Restored brightness to {}%", val);
	}
	Ok(())
}
