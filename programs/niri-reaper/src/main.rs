use std::collections::{HashMap, HashSet};
use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

/// Query `flatpak ps` and return a map of host PID → flatpak app ID.
fn get_running_flatpaks() -> HashMap<u32, String> {
    let mut map = HashMap::new();
    let output = match Command::new("flatpak")
        .args(["ps", "--columns=pid,application"])
        .output()
    {
        Ok(o) => o,
        Err(_) => return map,
    };
    let text = String::from_utf8_lossy(&output.stdout);
    for line in text.lines() {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 2 {
            if let Ok(pid) = parts[0].parse::<u32>() {
                map.insert(pid, parts[1].to_string());
            }
        }
    }
    map
}

/// Check if a specific PID belongs to a flatpak process.
/// Walks up the process tree (via /proc/{pid}/status PPid) since
/// niri may report a child PID, not the flatpak bwrap root.
fn find_flatpak_app_id(pid: u32) -> Option<String> {
    let flatpaks = get_running_flatpaks();

    // Check the pid itself and walk up parent chain
    let mut current = pid;
    for _ in 0..10 {
        if let Some(app_id) = flatpaks.get(&current) {
            return Some(app_id.clone());
        }
        // Read PPid from /proc/{current}/status
        match std::fs::read_to_string(format!("/proc/{current}/status")) {
            Ok(status) => {
                let ppid = status.lines()
                    .find(|l| l.starts_with("PPid:"))
                    .and_then(|l| l.split_whitespace().nth(1))
                    .and_then(|p| p.parse::<u32>().ok());
                match ppid {
                    Some(p) if p > 1 => current = p,
                    _ => break,
                }
            }
            Err(_) => break,
        }
    }
    None
}

/// Track a window. Checks flatpak ps to determine if it's a flatpak process.
fn track_window(
    window_to_app: &mut HashMap<u64, String>,
    app_windows: &mut HashMap<String, HashSet<u64>>,
    w: &serde_json::Value,
) {
    let id = match w.get("id").and_then(|i| i.as_u64()) {
        Some(id) => id,
        None => return,
    };
    let pid = match w.get("pid").and_then(|p| p.as_u64()) {
        Some(p) => p as u32,
        None => return,
    };

    // Already tracked
    if window_to_app.contains_key(&id) {
        return;
    }

    if let Some(app_id) = find_flatpak_app_id(pid) {
        eprintln!("niri-reaper: tracking window {id} → {app_id} (pid {pid})");
        window_to_app.insert(id, app_id.clone());
        app_windows.entry(app_id).or_default().insert(id);
    } else {
        eprintln!("niri-reaper: window {id} (pid {pid}) is not a flatpak, ignoring");
    }
}

/// Run one cycle of the event loop. Returns false if the stream dies.
fn run_event_loop() -> bool {
    let mut child = match Command::new("niri")
        .args(["msg", "-j", "event-stream"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            eprintln!("niri-reaper: failed to start event stream: {e}");
            return false;
        }
    };

    let stdout = match child.stdout.take() {
        Some(s) => s,
        None => return false,
    };

    let reader = BufReader::new(stdout);

    // window_id → flatpak app ID
    let mut window_to_app: HashMap<u64, String> = HashMap::new();
    // flatpak app ID → set of open window IDs
    let mut app_windows: HashMap<String, HashSet<u64>> = HashMap::new();

    for line in reader.lines() {
        let line = match line {
            Ok(l) => l,
            Err(e) => {
                eprintln!("niri-reaper: read error: {e}");
                continue;
            }
        };

        let event: serde_json::Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(_) => continue,
        };

        // Full window list (sent on connect and on workspace changes)
        if let Some(ws) = event.get("WindowsChanged") {
            if let Some(wins) = ws.get("windows").and_then(|w| w.as_array()) {
                window_to_app.clear();
                app_windows.clear();
                for w in wins {
                    track_window(&mut window_to_app, &mut app_windows, w);
                }
            }
        }

        // Single window opened or changed
        if let Some(w) = event.get("WindowOpenedOrChanged") {
            if let Some(win) = w.get("window") {
                track_window(&mut window_to_app, &mut app_windows, win);
            }
        }

        // Window closed — kill flatpak only when last window for that app closes
        if let Some(wc) = event.get("WindowClosed") {
            if let Some(id) = wc.get("id").and_then(|i| i.as_u64()) {
                if let Some(app_id) = window_to_app.remove(&id) {
                    if let Some(windows) = app_windows.get_mut(&app_id) {
                        windows.remove(&id);
                        if windows.is_empty() {
                            app_windows.remove(&app_id);
                            eprintln!("niri-reaper: last window for {app_id} closed, killing");
                            let _ = Command::new("flatpak")
                                .args(["kill", &app_id])
                                .status();
                        } else {
                            eprintln!(
                                "niri-reaper: window {id} closed for {app_id}, {} remaining",
                                windows.len()
                            );
                        }
                    }
                }
            }
        }
    }

    let _ = child.wait();
    false
}

fn main() {
    eprintln!("niri-reaper: starting");

    loop {
        if run_event_loop() {
            break;
        }
        eprintln!("niri-reaper: event stream ended, reconnecting in 2s");
        thread::sleep(Duration::from_secs(2));
    }
}
