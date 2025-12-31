use log::{debug, error, info};
use serde::Deserialize;
use std::collections::HashMap;
use std::process::Command;
use std::sync::{Arc, Mutex};
use zbus::{connection, interface, Connection};

#[derive(Debug, Deserialize, Clone)]
struct NtlStatus {
    icon: String,
    status: String,
    #[serde(default)]
    critical: u32,
    #[serde(default)]
    warning: u32,
}

impl Default for NtlStatus {
    fn default() -> Self {
        Self {
            icon: "󰔟".to_string(),
            status: "pending".to_string(),
            critical: 0,
            warning: 0,
        }
    }
}

fn update_status(status: &Arc<Mutex<NtlStatus>>) {
    debug!("Running ntl tray...");
    match Command::new("ntl").arg("tray").output() {
        Ok(output) => {
            if let Ok(stdout) = String::from_utf8(output.stdout) {
                debug!("stdout: {}", stdout.trim());
                if let Ok(new_status) = serde_json::from_str::<NtlStatus>(&stdout) {
                    debug!("Parsed status: {:?}", new_status);
                    let mut s = status.lock().unwrap();
                    *s = new_status;
                }
            }
        }
        Err(e) => error!("Failed to run ntl tray: {}", e),
    }
}

struct StatusNotifierItem {
    status: Arc<Mutex<NtlStatus>>,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
    #[zbus(property)]
    fn category(&self) -> String {
        "SystemServices".to_string()
    }

    #[zbus(property)]
    fn id(&self) -> String {
        "ntl-daemon".to_string()
    }

    #[zbus(property)]
    fn title(&self) -> String {
        "NTL Security Monitor".to_string()
    }

    #[zbus(property)]
    fn status(&self) -> String {
        "Active".to_string()
    }

    #[zbus(property)]
    fn icon_name(&self) -> String {
        let status = self.status.lock().unwrap();
        match status.status.as_str() {
            "ok" => "security-high-symbolic",
            "warning" => "security-medium-symbolic",
            "critical" => "security-low-symbolic",
            "inactive" => "security-low-symbolic",
            _ => "dialog-question-symbolic",
        }.to_string()
    }

    #[zbus(property)]
    fn icon_theme_path(&self) -> String {
        String::new()
    }

    #[zbus(property)]
    fn menu(&self) -> zbus::zvariant::OwnedObjectPath {
        zbus::zvariant::OwnedObjectPath::try_from("/MenuBar").unwrap()
    }

    fn activate(&self, _x: i32, _y: i32) {
        info!("Tray icon activated");
        let _ = Command::new("alacritty")
            .args(["-e", "ntl", "report"])
            .spawn();
    }

    fn secondary_activate(&self, _x: i32, _y: i32) {
        info!("Tray icon secondary activated");
        let _ = Command::new("alacritty")
            .args(["-e", "ntl", "run"])
            .spawn();
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::Builder::from_env(
        env_logger::Env::default().default_filter_or("debug")
    ).init();

    info!("NTL Daemon starting...");

    let status = Arc::new(Mutex::new(NtlStatus::default()));
    update_status(&status);
    info!("Status: {:?}", *status.lock().unwrap());

    let conn = Connection::session().await?;
    info!("Connected to session bus");

    let sni = StatusNotifierItem {
        status: status.clone(),
    };

    let object_path = "/StatusNotifierItem";
    conn.object_server().at(object_path, sni).await?;
    info!("Registered object at {}", object_path);

    // Request a unique name
    let well_known_name = format!("org.kde.StatusNotifierItem-{}-1", std::process::id());
    conn.request_name(&*well_known_name).await?;
    info!("Acquired name: {}", well_known_name);

    // Register with the watcher
    let watcher = conn.call_method(
        Some("org.kde.StatusNotifierWatcher"),
        "/StatusNotifierWatcher",
        Some("org.kde.StatusNotifierWatcher"),
        "RegisterStatusNotifierItem",
        &(well_known_name.as_str()),
    ).await;

    match watcher {
        Ok(_) => info!("Registered with StatusNotifierWatcher"),
        Err(e) => error!("Failed to register with watcher: {}", e),
    }

    info!("Running event loop...");
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(300)).await;
        update_status(&status);
    }
}
