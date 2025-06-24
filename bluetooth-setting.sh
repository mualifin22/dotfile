#!/usr/bin/env bash

# --- Ikon (Nerd Fonts direkomendasikan) ---
ICON_BT_ON="bật Enable Bluetooth"
ICON_BT_OFF="󰂲 Disable Bluetooth"
ICON_SCAN="magnify Scan"
ICON_CONNECT="󰂬 Connect"
ICON_DISCONNECT="󰂲 Disconnect"
ICON_PAIR="󰂫 Pair"
ICON_REMOVE=" Remove"
ICON_DEVICE="bluetooth"
ICON_STATUS_CONNECTED="󰂬"
ICON_STATUS_PAIRED="󰂫"
ICON_BACK="← Back"

# Periksa status Bluetooth
bluetooth_status=$(rfkill list bluetooth | grep -i 'Soft blocked' | awk '{print $3}')

if [[ "$bluetooth_status" == "no" ]]; then
    toggle="$ICON_BT_OFF"
elif [[ "$bluetooth_status" == "yes" ]]; then
    toggle="$ICON_BT_ON"
fi

# Pastikan Bluetooth nyala sebelum scan
if [[ "$bluetooth_status" == "yes" ]]; then
    rfkill unblock bluetooth
    bluetoothctl power on > /dev/null
    sleep 2
fi

# Ambil daftar perangkat dengan ikon status
device_list=""
while IFS= read -r line; do
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d' ' -f3-)
    info=$(bluetoothctl info "$mac")
    icon=""

    if echo "$info" | grep -q "Connected: yes"; then
        icon="$ICON_STATUS_CONNECTED"
    elif echo "$info" | grep -q "Paired: yes"; then
        icon="$ICON_STATUS_PAIRED"
    else
        icon="$ICON_DEVICE"
    fi

    device_list+="$icon $mac $name\n"
done < <(bluetoothctl devices)

# Tampilkan menu utama Rofi
rofi_menu=$(echo -e "$toggle\n$ICON_SCAN\n$device_list" | rofi -dmenu -i -p "Bluetooth: ")

# Proses pilihan user
if [[ "$rofi_menu" == "" ]]; then
    exit
elif [[ "$rofi_menu" == "$ICON_BT_ON" ]]; then
    rfkill unblock bluetooth
    bluetoothctl power on
    notify-send "Bluetooth" "Bluetooth enabled"
    exit
elif [[ "$rofi_menu" == "$ICON_BT_OFF" ]]; then
    bluetoothctl power off
    rfkill block bluetooth
    notify-send "Bluetooth" "Bluetooth disabled"
    exit
elif [[ "$rofi_menu" == "$ICON_SCAN" ]]; then
    bluetoothctl scan on
    notify-send "Bluetooth" "Scanning for 10 seconds..."
    sleep 10

    # Coba stop scan, tapi hanya kalau masih aktif
    if bluetoothctl show | grep -q "Discovering: yes"; then
        bluetoothctl scan off
    fi

    exec "$0"  # Refresh device list
else
    # Ambil MAC dari pilihan
    read -r _ mac name <<< "$rofi_menu"

    # Sub-menu untuk perangkat
    action=$(echo -e "$ICON_CONNECT\n$ICON_DISCONNECT\n$ICON_PAIR\n$ICON_REMOVE\n$ICON_BACK" | rofi -dmenu -i -p "$name")

    case "$action" in
        "$ICON_CONNECT")
            bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $name"
            ;;
        "$ICON_DISCONNECT")
            bluetoothctl disconnect "$mac" && notify-send "Bluetooth" "Disconnected from $name"
            ;;
        "$ICON_PAIR")
            bluetoothctl pair "$mac" && notify-send "Bluetooth" "Paired with $name"
            ;;
        "$ICON_REMOVE")
            bluetoothctl remove "$mac" && notify-send "Bluetooth" "Removed $name"
            ;;
        "$ICON_BACK")
            exec "$0"
            ;;
    esac
fi
