use super::Scanner;
use crate::report::{Report, ScanLevel};
use crate::config;
use crate::Args;
use anyhow::Result;
use procfs::net::TcpNetEntry;

pub struct NetworkScanner;

impl Scanner for NetworkScanner {
    fn scan(&self, report: &mut Report, _args: &Args) -> Result<()> {
        println!("Running Network Scan...");

        if let Ok(tcp) = procfs::net::tcp() {
            check_listeners(report, tcp.into_iter());
        }
        
        if let Ok(tcp6) = procfs::net::tcp6() {
            check_listeners(report, tcp6.into_iter());
        }

        Ok(())
    }
}

fn check_listeners<I>(report: &mut Report, entries: I)
where
    I: Iterator<Item = TcpNetEntry>,
{
    let suspicious_ports = config::SUSPICIOUS_PORTS;

    for entry in entries {
        report.increment_checked();
        if entry.state == procfs::net::TcpState::Listen {
            let port = entry.local_address.port();
            
            if suspicious_ports.contains(&port) {
                report.add_issue(
                    ScanLevel::Warning,
                    "Network",
                    &format!("Listening on suspicious port: {}", port)
                );
            }
        }
    }
}
