use super::Scanner;
use crate::report::{Report, ScanLevel};
use crate::Args;
use anyhow::Result;
use walkdir::WalkDir;
use std::os::unix::fs::PermissionsExt;
use std::fs;

pub struct FsScanner;

impl Scanner for FsScanner {
    fn scan(&self, report: &mut Report, _args: &Args) -> Result<()> {
        println!("Running Filesystem Scan...");
        for entry in WalkDir::new("/home").min_depth(2).max_depth(3) {
            let entry = match entry { Ok(e) => e, Err(_) => continue };
            if entry.file_name() == "authorized_keys" {
                if let Ok(content) = fs::read_to_string(entry.path()) {
                    report.increment_checked();
                    if content.lines().count() > 5 {
                        report.add_issue(
                            ScanLevel::Warning,
                            "SSH",
                            &format!("User has many authorized keys: {:?}", entry.path())
                        );
                    }
                }
            }
        }
        
        let critical_paths = ["/etc/passwd", "/etc/shadow", "/etc/sudoers"];
        for path in critical_paths {
            if let Ok(metadata) = fs::metadata(path) {
                report.increment_checked();
                let mode = metadata.permissions().mode();
                // Check if world writable (bit 2)
                if mode & 0o002 != 0 {
                    report.add_issue(
                        ScanLevel::Critical,
                        "FileSystem",
                        &format!("Critical file is world writable! {}", path)
                    );
                }
            }
        }

        Ok(())
    }
}
