use niri_ipc::socket::Socket;
use niri_ipc::{Action, Request};
use anyhow::Result;

pub fn dpms_off() -> Result<()> {
    let mut socket = Socket::connect()?;
    socket.send(Request::Action(Action::PowerOffMonitors {}))?;
    Ok(())
}

pub fn dpms_on() -> Result<()> {
    let mut socket = Socket::connect()?;
    socket.send(Request::Action(Action::PowerOnMonitors {}))?;
    Ok(())
}
