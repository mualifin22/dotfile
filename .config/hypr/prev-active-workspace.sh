#!/bin/bash

current=$(hyprctl activeworkspace -j | jq ".id")
workspaces=($(hyprctl workspaces -j | jq -r 'sort_by(.id) | .[].id'))

index=-1
for i in "${!workspaces[@]}"; do
  if [[ "${workspaces[$i]}" == "$current" ]]; then
    index=$i
    break
  fi
done

if [[ $index -ge 0 ]]; then
  prev_index=$((index - 1))
  if [[ $prev_index -ge 0 ]]; then
    hyprctl dispatch workspace "${workspaces[$prev_index]}"
  else
    # Kalau sudah di awal, lompat ke yang terakhir (wrap around)
    hyprctl dispatch workspace "${workspaces[-1]}"
  fi
fi
