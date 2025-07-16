#!/usr/bin/env zsh

get_bluetooth_status() {
    if ! command -v bluetoothctl &> /dev/null; then
        echo "ERROR: bluetoothctl not available"
        exit 1
    fi
    
    # Simple check - just see if bluetooth is powered
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "on"
    else
        echo "off"
    fi
}

get_bluetooth_icon() {
    bt_status=$(get_bluetooth_status)
    case "$bt_status" in
        connected)
            echo "%{F#4a90e2} %{F-}"
            ;;
        on)
            echo "%{F#B0B0B0} %{F-}"
            ;;
        off)
            echo "%{F#B0B0B0} %{F-}"
            ;;
        ERROR:*)
            echo "%{F#A54242} %{F-}"
            ;;
    esac
}

filter_devices() {
    # Filter out spam devices - keep common device types
    grep -E "(Audio|Headphones|Headset|Speaker|Keyboard|Mouse|Phone|Tablet|Laptop|Computer)" || \
    grep -v -E "(LE-|^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$)"
}

connect_bluetooth() {
    local device_mac="$1"
    
    bluetoothctl pair "$device_mac"
    bluetoothctl trust "$device_mac"
    bluetoothctl connect "$device_mac"
}

show_bluetooth_menu() {
    bt_status=$(get_bluetooth_status)
    
    if [ "$bt_status" = "off" ]; then
        choice=$(echo -e "Turn On Bluetooth" | rofi -dmenu -p "Bluetooth:")
        if [ "$choice" = "Turn On Bluetooth" ]; then
            bluetoothctl power on
        fi
        return
    fi
    
    # Just show paired devices for now - no scanning to avoid hanging
    paired=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2 " " substr($0, index($0,$3))}' | head -10)
    
    if [ -z "$paired" ]; then
        rofi -e "No paired Bluetooth devices found"
        return
    fi
    
    selected=$(echo "$paired" | rofi -dmenu -p "Select Bluetooth Device:" -i)
    
    if [ -n "$selected" ]; then
        device_mac=$(echo "$selected" | awk '{print $1}')
        
        # Simple connect/disconnect toggle
        if bluetoothctl info "$device_mac" 2>/dev/null | grep -q "Connected: yes"; then
            bluetoothctl disconnect "$device_mac"
        else
            bluetoothctl connect "$device_mac"
        fi
    fi
}

case "$1" in
    "status")
        get_bluetooth_icon
        ;;
    "menu")
        show_bluetooth_menu
        ;;
    *)
        get_bluetooth_icon
        ;;
esac
