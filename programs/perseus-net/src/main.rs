use anyhow::{Context, Result};
use clap::Parser;
use networkmanager::devices::{Device, Wireless};
use networkmanager::NetworkManager;
use dbus::blocking::Connection;
use std::collections::HashMap;
use std::io::Write;
use std::process::{Command, Stdio};
use std::time::Duration;

#[derive(Parser, Debug)]
#[command(author, version, about)]
struct Args {}

fn main() -> Result<()> {
    let _args = Args::parse();

    let dbus_conn = Connection::new_system()?;
    let nm = NetworkManager::new(&dbus_conn);
    
    let mut wifi_device = None;
    
    if let Ok(devices) = nm.get_devices() {
        for dev in devices {
            if let Device::WiFi(wifi) = dev {
                wifi_device = Some(wifi);
                break;
            }
        }
    }

    let wifi = wifi_device.context("No WiFi device found")?;

    let _ = wifi.request_scan(HashMap::new());
    
    std::thread::sleep(Duration::from_millis(200));

    let access_points = wifi.get_access_points()
        .map_err(|e| anyhow::anyhow!("NM Error: {:?}", e))?;

    let mut unique_aps: HashMap<String, (u8, u32)> = HashMap::new(); 

    for ap in access_points {
        let ssid = ap.ssid().unwrap_or_default();
        if ssid.is_empty() { continue; }

        let strength = ap.strength().unwrap_or(0);
        let flags = ap.rsn_flags().unwrap_or(0);
        
        match unique_aps.get(&ssid) {
            Some((existing_strength, _)) => {
                if strength > *existing_strength {
                    unique_aps.insert(ssid, (strength, flags));
                }
            }
            None => {
                unique_aps.insert(ssid, (strength, flags));
            }
        }
    }

    let mut menu_items = Vec::new();
    let mut sorted_ssids: Vec<String> = unique_aps.keys().cloned().collect();
    sorted_ssids.sort(); 

    menu_items.push("❌ Disconnect".to_string());

    for ssid in &sorted_ssids {
        let (strength, flags) = unique_aps.get(ssid).unwrap();
        
        let icon = match strength {
            0..=25 => "󰤯",
            26..=50 => "󰤟",
            51..=75 => "󰤢",
            76..=100 => "󰤨",
            _ => "󰤯",
        };

        let lock = if *flags == 0 { "⚠️ OPEN" } else { "🔒" };

        menu_items.push(format!("{} {} ({})", icon, ssid, lock));
    }

    let selection = show_rofi(&menu_items)?;

    if selection.is_empty() {
        return Ok(());
    }

    if selection.contains("Disconnect") {
        println!("Disconnecting...");
        Command::new("nmcli").args(["device", "disconnect", "wlan0"]).spawn()?;
    } else {
        let parts: Vec<&str> = selection.split_whitespace().collect();
        if parts.len() >= 2 {
            let ssid = parts[1];
            connect_to_network(ssid)?;
        }
    }

    Ok(())
}

fn show_rofi(items: &[String]) -> Result<String> {
    let input = items.join("\n");
    
    let mut child = Command::new("rofi")
        .arg("-dmenu")
        .arg("-p").arg("Wi-Fi")
        .arg("-i")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(input.as_bytes())?;
    }

    let output = child.wait_with_output()?;
    let selection = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(selection)
}

fn connect_to_network(ssid: &str) -> Result<()> {
    let status = Command::new("nmcli")
        .args(["device", "wifi", "connect", ssid])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()?;

    if !status.success() {
        let password = get_password_rofi(ssid)?;
        if !password.is_empty() {
             Command::new("nmcli")
                .args(["device", "wifi", "connect", ssid, "password", &password])
                .spawn()?;
        }
    }
    
    Ok(())
}

fn get_password_rofi(ssid: &str) -> Result<String> {
    let child = Command::new("rofi")
        .arg("-dmenu")
        .arg("-p").arg(format!("Password for {}", ssid))
        .arg("-password")
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .spawn()?;

    let output = child.wait_with_output()?;
    let pass = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(pass)
}
