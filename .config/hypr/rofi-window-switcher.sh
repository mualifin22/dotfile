#!/bin/bash

# Ambil daftar window dengan address penuh
choice=$(hyprctl clients -j | jq -r '.[] | "\(.class) - \(.title) ::: \(.address)"' | \
  rofi -dmenu -p "Window:")

# Jika ada yang dipilih
if [ -n "$choice" ]; then
  # Ambil address setelah ::: (biarkan tetap ada "0x" jika ada)
  address=$(echo "$choice" | awk -F '::: ' '{print $2}' | xargs)
  
  # Fokuskan ke jendela yang dipilih
  hyprctl dispatch focuswindow address "$address"
fi
