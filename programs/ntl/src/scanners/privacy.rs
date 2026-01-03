use super::Scanner;
use crate::report::{Report, ScanLevel};
use crate::config; 
use crate::Args;
use anyhow::Result;
use std::fs;
use std::net::ToSocketAddrs;
use std::process::Command;

pub struct PrivacyScanner;

impl Scanner for PrivacyScanner {
    fn scan(&self, report: &mut Report, _args: &Args) -> Result<()> {
        println!("Running Privacy & Telemetry Scan...");

        // 1. DNS LEAK CHECK
        check_dns_resolver(report);

        // 2. TELEMETRY BLOCK CHECK
        check_telemetry_blocks(report);

        // 3. HARDWARE TRACKING CHECK
        check_mac_privacy(report);

        // 4. [NEW] RUNTIME DNS LEAK CHECK
        check_runtime_dns_leaks(report);

        Ok(())
    }
}

fn check_dns_resolver(report: &mut Report) {
    report.increment_checked();
    if let Ok(content) = fs::read_to_string("/etc/resolv.conf") {
        let mut using_localhost = false;
        
        for line in content.lines() {
            if line.starts_with("nameserver") {
                // Check against centralized constants
                if line.contains(config::LOCALHOST_V4) || line.contains(config::LOCALHOST_V6) {
                    using_localhost = true;
                } else if line.contains("8.8.8.8") || line.contains("8.8.4.4") {
                    report.add_issue(ScanLevel::Warning, "Privacy", "System is using Google DNS! Queries are likely logged.");
                } else if line.contains("1.1.1.1") {
                    report.add_issue(ScanLevel::Info, "Privacy", "System is using Cloudflare DNS. Better than Google, but not private.");
                }
            }
        }

        if !using_localhost {
            report.add_issue(
                ScanLevel::Warning, 
                "Privacy", 
                &format!("DNS is not routed through localhost ({}/DNSCrypt). ISP may be spying.", config::LOCALHOST_V4)
            );
        }
    }
}

fn check_telemetry_blocks(report: &mut Report) {
    let domains = config::spy_domains();

    for domain in domains {
        report.increment_checked();
        
        let address_str = format!("{}:80", domain);
        
        match address_str.to_socket_addrs() {
            Ok(mut addrs) => {
                if let Some(socket) = addrs.next() {
                    let ip = socket.ip().to_string();
                    
                    let is_blocked = ip == config::BLOCKED_IP 
                        || ip == config::LOCALHOST_V4 
                        || ip == config::LOCALHOST_V6;

                    if !is_blocked {
                         report.add_issue(
                            ScanLevel::Critical, 
                            "Telemetry", // Returns a Set of known telemetry/spyware domains
                            &format!("Telemetry Leak! Domain '{}' resolves to {}. It should be blocked ({}).", domain, ip, config::BLOCKED_IP)
                        );
                    }
                }
            },
            Err(_) => {
            }
        }
    }
}

fn check_mac_privacy(report: &mut Report) {
    report.increment_checked();
    
    let nm_conf = "/etc/NetworkManager/NetworkManager.conf";
    if let Ok(content) = fs::read_to_string(nm_conf) {
        if !content.contains("wifi.scan-rand-mac-address=yes") && !content.contains("wifi.scan-rand-mac-address=true") {
             report.add_issue(
                ScanLevel::Warning, 
                "Tracking", 
                "WiFi MAC Address randomization does not appear to be enforced in global config."
            );
        }
    }
}


fn check_runtime_dns_leaks(report: &mut Report) {
    report.increment_checked();

    // Check for established connections to port 53
    if let Ok(output) = Command::new("ss")
        .args(["-tunp", "state", "established"])
        .output()
    {
        let stdout = String::from_utf8_lossy(&output.stdout);
        for line in stdout.lines() {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() >= 5 {
                let remote = parts[4];
                if remote.ends_with(":53")
                    && !remote.starts_with("127.0.0.1:")
                    && !remote.starts_with("[::1]:")
                    && !remote.starts_with("127.0.0.53:")
                {
                    report.add_issue(
                        ScanLevel::Critical,
                        "DNSLeak",
                        &format!("Active DNS connection bypassing localhost: {}", line.trim())
                    );
                }
            }
        }
    }

    // Check for UDP sockets to port 53
    if let Ok(output) = Command::new("ss")
        .args(["-unp"])
        .output()
    {
        let stdout = String::from_utf8_lossy(&output.stdout);
        for line in stdout.lines() {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() >= 5 {
                let remote = parts[4];
                if remote.ends_with(":53")
                    && !remote.starts_with("127.0.0.1:")
                    && !remote.starts_with("[::1]:")
                    && !remote.starts_with("127.0.0.53:")
                    && !remote.starts_with("*:")
                {
                    report.add_issue(
                        ScanLevel::Warning,
                        "DNSLeak",
                        &format!("Process with external DNS socket: {}", line.trim())
                    );
                }
            }
        }
    }
}
