#[derive(Debug)]
pub enum DbusCommand {
    RequestSuspend,
    RequestLidClosedSuspend,
}

#[derive(Debug)]
pub enum WaylandCommand {
    LidClosed,
    LidOpened,
}
