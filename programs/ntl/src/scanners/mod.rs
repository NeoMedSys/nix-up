use crate::report::Report;
use crate::Args;
use anyhow::Result;

pub mod process;
pub mod network;
pub mod filesystem;
pub mod nix;
pub mod privacy;

pub trait Scanner {
    fn scan(&self, report: &mut Report, args: &Args) -> Result<()>;
}
