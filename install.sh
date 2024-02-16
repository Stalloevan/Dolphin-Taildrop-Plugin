#!/usr/bin/env bash

# Main function
main() {
  # Define the path for the .desktop file
  local desktop_file_path="${HOME}/.local/share/kservices5/ServiceMenus/Taildrop.desktop"

  # Create or update the .desktop file using a heredoc
  cat << EOF > "${desktop_file_path}"
# -*- coding: UTF-8 -*-
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=all/all;
Actions=default_action;
X-KDE-StartupNotify=false
X-KDE-Priority=TopLevel
X-KDE-Submenu=
Name=Taildrop
Icon=\$HOME/Themes/Icons/tailscale.png
Exec=\$HOME/.config/dolphin_service_menus_creator/script_Taildrop.sh %F

[Desktop Action default_action]
X-KDE-Priority=TopLevel
X-KDE-Submenu=
Name=Taildrop
Icon=\$HOME/Themes/Icons/tailscale.png
Exec=\$HOME/.config/dolphin_service_menus_creator/script_Taildrop.sh %F
EOF

  local friendly_name_list status_output device_list
  status_output=$(tailscale status)
  friendly_name_list=()
  device_list=()

  local line friendly_name
  while IFS= read -r line; do
    friendly_name=$(echo "${line}" | awk '{print $2}')
    friendly_name_list+=("${friendly_name}")
  done <<< "${status_output}"

  echo "${friendly_name_list[@]}"

  # Only include online external devices in the list
  local name ping
  for name in "${friendly_name_list[@]}"; do
    echo "${name}"
    # Check to see if the device is connected
    ping=$(tailscale ping --timeout .01s "${name}")

    if [[ ${ping} == *pong* ]]; then
      # Add the friendly name to the list with 'on' state
      device_list+=("${name}" "${name}" on)
    else
      # Add the friendly name to the list with 'off' state
      device_list+=("${name}" "${name}" off)
    fi

  done
  echo "${device_list[@]}"

  # Display popup to choose device from list
  local chosen_device list_name short_name list
  chosen_device=$(kdialog --title 'Taildrop' --radiolist "Choose Device" "${device_list[@]}" --geometry 200x50)

  # Check again to see if device is connected
  ping=$(tailscale ping --timeout .01s "${chosen_device}")
  if [[ ${ping} == *pong* ]]; then

    # Loop through selected items in Dolphin
    local file
    for file in "$@"; do
      # Execute taildrop command to chosen device
      tailscale file cp "${file}" "${chosen_device}":
      # Extract the short file name using parameter expansion
      short_name="${file##*/}"
      # Check if there are multiple entries in the array
      if [[ ${file} != "${*: -1}" ]]; then
        # If not the last iteration, add ', ' to the short_name
        list_name="${short_name}"', '
      else
        # If there is only one entry, use it directly
        list_name="${short_name}"
      fi
      # Add the short file name to the array
      list+=("${list_name}")
    done

    # Show notification
    kdialog --title 'Taildrop' --passivepopup "$(echo $"${list[@]}" 'delivered')" --icon file:///home/e/Themes/Icons/tailscale.png
  else
    kdialog --title 'Taildrop' --passivepopup "$(echo $"${chosen_device}" 'is offline')" --icon file:///home/e/Themes/Icons/tailscale.png
  fi
}

main "$@"
