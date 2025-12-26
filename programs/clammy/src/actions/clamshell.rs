use log::{debug, info, error};

pub fn apply_clamshell_config(_state: &crate::state::State) -> anyhow::Result<()> {
    use niri_ipc::socket::Socket;
    use niri_ipc::{Request, OutputAction};
    
    info!("Applying clamshell config: turning off eDP-1");
    
    let mut socket = Socket::connect().map_err(|e| {
        error!("Failed to connect to niri socket: {}", e);
        anyhow::anyhow!("Socket connect failed: {}", e)
    })?;
    
    debug!("Connected to niri socket, sending OutputAction::Off for eDP-1");
    
    let reply = socket.send(Request::Output {
        output: "eDP-1".to_string(),
        action: OutputAction::Off,
    })?;
    
    match &reply {
        Ok(response) => info!("niri replied OK: {:?}", response),
        Err(e) => error!("niri replied with error: {}", e),
    }
    
    reply.map_err(|e| anyhow::anyhow!("niri error: {}", e))?;
    info!("eDP-1 turned off successfully");
    Ok(())
}
