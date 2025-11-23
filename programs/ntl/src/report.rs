use colored::*;
use chrono::Local;
use notify_rust::Notification;

pub enum ScanLevel {
    Info,
    Warning,
    Critical,
}

struct Issue {
    level: ScanLevel,
    category: String,
    message: String,
}

pub struct Report {
    issues: Vec<Issue>,
    checked_items: u32,
}

impl Report {
    pub fn new() -> Self {
        Self {
            issues: Vec::new(),
            checked_items: 0,
        }
    }

    pub fn add_issue(&mut self, level: ScanLevel, category: &str, message: &str) {
        self.issues.push(Issue {
            level,
            category: category.to_string(),
            message: message.to_string(),
        });
    }

    pub fn increment_checked(&mut self) {
        self.checked_items += 1;
    }

    pub fn has_critical(&self) -> bool {
        self.issues.iter().any(|i| matches!(i.level, ScanLevel::Critical))
    }

    pub fn print_summary(&self) {
        println!("\n{}", "=== Audit Summary ===".bold());
        println!("Items Checked: {}", self.checked_items);
        
        if self.issues.is_empty() {
            println!("{}", "✅ No issues found. System appears clean.".green());
            return;
        }

        let mut critical_count = 0;

        for issue in &self.issues {
            match issue.level {
                ScanLevel::Critical => {
                    println!("{} [{}]: {}", "CRITICAL".red().bold(), issue.category, issue.message);
                    critical_count += 1;
                },

                ScanLevel::Warning => println!("{} [{}]: {}", "WARNING".yellow(), issue.category, issue.message),
                ScanLevel::Info => println!("{} [{}]: {}", "INFO".blue(), issue.category, issue.message),
            }
        }

        if critical_count > 0 {
            let summary = format!("🚨 Security Alert: {} Critical Issues!", critical_count);
            let body = "Check /var/log/nastyTechLords/ for details.";
            
            let _ = Notification::new()
                .summary(&summary)
                .body(body)
                .icon("security-high")
                .timeout(0)
                .show();
        }
    }

    pub fn generate_text_log(&self) -> String {
        let mut out = String::new();
        out.push_str(&format!("Audit Run: {}\n", Local::now()));
        out.push_str(&format!("Hostname: {:?}\n\n", hostname::get().unwrap_or_default()));
        
        for issue in &self.issues {
            let lvl = match issue.level {
                ScanLevel::Critical => "CRITICAL",
                ScanLevel::Warning => "WARNING",
                ScanLevel::Info => "INFO",
            };
            out.push_str(&format!("[{}] [{}] {}\n", lvl, issue.category, issue.message));
        }
        out
    }
}
