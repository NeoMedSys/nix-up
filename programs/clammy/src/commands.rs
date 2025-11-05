#[derive(Debug)]
pub enum Command {
    LidClosed,
    LidOpened,
}
    
#[derive(Debug)]
pub enum DbusCommand {
    RequestSuspend,
}
