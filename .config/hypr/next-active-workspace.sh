#!/bin/bash

# Ambil workspace aktif saat ini
current=$(hyprctl activeworkspace -j | jq ".id")

# Ambil semua workspace yang sedang aktif (ada jendela), diurutkan
workspaces=($(hyprctl workspaces -j | jq -r 'sort_by(.id) | .[].id'))

# Cari index workspace saat ini dalam daftar
index=-1
for i in "${!workspaces[@]}"; do
  if [[ "${workspaces[$i]}" == "$current" ]]; then
    index=$i
    break
  fi
done

# Jika ditemukan dan ada workspace selanjutnya
if [[ $index -ge 0 ]]; then
  next_index=$((index + 1))
  if [[ $next_index -lt ${#workspaces[@]} ]]; then
    hyprctl dispatch workspace "${workspaces[$next_index]}"
  else
    # Kalau sudah di akhir, kembali ke awal (wrap around)
    hyprctl dispatch workspace "${workspaces[0]}"
  fi
fi
