use super::Scanner;
use crate::report::{Report, ScanLevel};
use crate::config;
use crate::Args;
use anyhow::Result;
use procfs::process::all_processes;
use std::collections::HashSet;

pub struct ProcessScanner;

impl Scanner for ProcessScanner {
    fn scan(&self, report: &mut Report, _args: &Args) -> Result<()> {
        println!("Running Process Scan...");
        
        let shell_names = config::shell_names();
        let suspicious_names = config::suspicious_process_names();

        let mut local_sockets = HashSet::new();
        if let Ok(unix_sockets) = procfs::net::unix() {
            for s in unix_sockets {
                local_sockets.insert(s.inode);
            }
        }

        for p in all_processes()? {
            if let Ok(process) = p {
                report.increment_checked();
                
                let stat = match process.stat() {
                    Ok(s) => s,
                    Err(_) => continue,
                };
                
                let owner_uid = process.uid().unwrap_or(u32::MAX);

                if owner_uid == 0 && suspicious_names.contains(stat.comm.as_str()) {
                    report.add_issue(
                        ScanLevel::Warning, 
                        "Process", 
                        &format!("Suspicious tool running as ROOT: {} (PID: {})", stat.comm, stat.pid)
                    );
                }

                if shell_names.contains(stat.comm.as_str()) {
                    if let Ok(fds) = process.fd() {
                        for fd_result in fds {
                            if let Ok(fd_info) = fd_result {
                                match fd_info.target {
                                    procfs::process::FDTarget::Socket(inode) => {
                                        if !local_sockets.contains(&inode) {
                                            report.add_issue(
                                                ScanLevel::Critical,
                                                "ReverseShell",
                                                &format!(
                                                    "Shell '{}' (PID: {}) is connected to a NON-LOCAL socket (inode: {})! Potential Reverse Shell.", 
                                                    stat.comm, stat.pid, inode
                                                )
                                            );
                                        }
                                    },
                                    _ => {}
                                }
                            }
                        }
                    }
                }
            }
        }
        Ok(())
    }
}
