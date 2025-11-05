#[derive(Debug)]
pub enum DbusCommand {
    RequestSuspend,
}

#[derive(Debug)]
pub enum WaylandCommand {
    LidClosed,
    LidOpened,
}
