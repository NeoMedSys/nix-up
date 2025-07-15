#!/usr/bin/env bash

get_bluetooth_status() {
    if ! command -v bluetoothctl &> /dev/null; then
        echo "ERROR: bluetoothctl not available"
        exit 1
    fi
    
    bt_power=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
    
    if [ "$bt_power" = "yes" ]; then
        connected=$(bluetoothctl devices Connected | wc -l)
        if [ "$connected" -gt 0 ]; then
            echo "connected"
        else
            echo "on"
        fi
    else
        echo "off"
    fi
}

get_bluetooth_icon() {
    status=$(get_bluetooth_status)
    case "$status" in
        connected)
            echo "%{F#4a90e2} %{F-}"
            ;;
        on)
            echo "%{F#C5C8C6} %{F-}"
            ;;
        off)
            echo "%{F#707880} %{F-}"
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
    
    # Get paired devices
    paired=$(bluetoothctl devices Paired | awk '{print $2 " " substr($0, index($0,$3))}' | filter_devices)
    
    # Start scan for available devices
    bluetoothctl scan on &
    scan_pid=$!
    sleep 2
    
    # Get discoverable devices (not paired)
    available=$(bluetoothctl devices | awk '{print $2 " " substr($0, index($0,$3))}' | filter_devices)
    available=$(echo "$available" | grep -v -F "$paired" | head -10)
    
    kill $scan_pid 2>/dev/null
    bluetoothctl scan off
    
    # Create menu
    menu=""
    if [ -n "$paired" ]; then
        menu="$menu--- PAIRED DEVICES ---\n$paired\n"
    fi
    if [ -n "$available" ]; then
        menu="$menu--- AVAILABLE DEVICES ---\n$available"
    fi
    
    if [ -z "$menu" ]; then
        rofi -e "No Bluetooth devices found"
        return
    fi
    
    selected=$(echo -e "$menu" | rofi -dmenu -p "Select Bluetooth Device:" -i)
    
    if [ -n "$selected" ] && [[ "$selected" != "---"* ]]; then
        device_mac=$(echo "$selected" | awk '{print $1}')
        device_name=$(echo "$selected" | cut -d' ' -f2-)
        
        # Check if already connected
        if bluetoothctl info "$device_mac" | grep -q "Connected: yes"; then
            bluetoothctl disconnect "$device_mac"
        else
            connect_bluetooth "$device_mac"
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
