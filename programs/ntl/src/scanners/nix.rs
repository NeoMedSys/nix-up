use super::Scanner;
use crate::report::{Report, ScanLevel};
use crate::Args;
use anyhow::Result;
use std::process::Command;

pub struct NixScanner;

impl Scanner for NixScanner {
    fn scan(&self, report: &mut Report, args: &Args) -> Result<()> {
        if !args.full { 
            return Ok(()); 
        }

        println!("Running Deep Nix Integrity Scan (This may take a while)...");
        let output = Command::new("nix-store")
            .args(["--verify", "--check-contents"])
            .output()?;

        let stderr = String::from_utf8_lossy(&output.stderr);
        for line in stderr.lines() {
            if line.contains("checking contents") { continue; } 
            
            if line.contains("lacks a signature") 
                || line.contains("corruption") 
                || line.contains("modification detected") {
                
                report.increment_checked();
                report.add_issue(
                    ScanLevel::Critical,
                    "NixIntegrity",
                    &format!("Integrity Violation: {}", line)
                );
            }
        }

        Ok(())
    }
}
