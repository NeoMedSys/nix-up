#!/usr/bin/env zsh

get_wifi_status() {
    if ! command -v nmcli &> /dev/null; then
        echo "ERROR: NetworkManager not available"
        exit 1
    fi
    
    connection=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
    if [ -n "$connection" ]; then
        echo "connected:$connection"
    else
        wifi_enabled=$(nmcli radio wifi)
        if [ "$wifi_enabled" = "enabled" ]; then
            echo "disconnected"
        else
            echo "disabled"
        fi
    fi
}

get_wifi_icon() {
    status=$(get_wifi_status)
    case "$status" in
        connected:*)
            echo "%{F#4a90e2} %{F-}"
            ;;
        disconnected)
            echo "%{F#B0B0B0} %{F-}"
            ;;
        disabled)
            echo "%{F#B0B0B0} %{F-}"
            ;;
        ERROR:*)
            echo "%{F#A54242} %{F-}"
            ;;
    esac
}

connect_wifi() {
    local ssid="$1"
    
    # Check if network is already saved
    if nmcli connection show "$ssid" &> /dev/null; then
        nmcli connection up "$ssid"
        return $?
    fi
    
    # Need password for new connection
    password=$(rofi -dmenu -password -p "Password for $ssid:" -mesg "Press Ctrl+Shift+p to toggle password visibility")
    
    if [ -n "$password" ]; then
        nmcli device wifi connect "$ssid" password "$password"
        return $?
    else
        return 1
    fi
}

show_wifi_menu() {
    # Get available networks
    networks=$(nmcli -t -f ssid,signal,security dev wifi | grep -v '^$' | sort -t':' -k2 -nr | awk -F':' '{
        if ($3 == "") security = "Open"
        else security = "Secured"
        printf "%-30s %s%% %s\n", $1, $2, security
    }' | head -20)
    
    if [ -z "$networks" ]; then
        rofi -e "No WiFi networks found"
        return
    fi
    
    selected=$(echo "$networks" | rofi -dmenu -p "Select WiFi Network:" -i)
    
    if [ -n "$selected" ]; then
        ssid=$(echo "$selected" | awk '{print $1}')
        
        # Show connecting state
        echo "%{F#F0C674} %{F-}" > /tmp/polybar_wifi_status
        
        if connect_wifi "$ssid"; then
            echo "%{F#4a90e2} %{F-}" > /tmp/polybar_wifi_status
        else
            echo "%{F#B0B0B0} %{F-}" > /tmp/polybar_wifi_status
            rofi -e "Failed to connect to $ssid"
        fi
    fi
}

case "$1" in
    "status")
        get_wifi_icon
        ;;
    "menu")
        show_wifi_menu
        ;;
    *)
        get_wifi_icon
        ;;
esac
