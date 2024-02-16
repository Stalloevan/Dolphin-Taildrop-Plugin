#!/usr/bin/env bash

# Downloads the Tailscale icon if it does not already exist in the specified path.
download_icon() {
  local icon_path="${HOME}/Themes/Icons/tailscale.png"
  if [[ ! -f ${icon_path}   ]]; then
    echo "Downloading Tailscale icon..."
        mkdir -p "$(dirname "${icon_path}")"
    curl -L "https://raw.githubusercontent.com/error-try-again/KDE-Dolphin-TailDrop-Plugin/main/tailscale.png" -o "${icon_path}"
  fi
}

# Configures Tailscale for receiving files via Taildrop by setting up a systemd service.
setup_taildrop_service() {
  echo "Setting up Tailscale for Taildrop..."

    # Elevate privileges to configure Tailscale with admin rights.
  sudo tailscale up --operator="${USER}"

  # Define directory for systemd unit files and Taildrop download directory
  local systemd_dir="${HOME}/.config/systemd/user"
  local taildrop_dir="${HOME}/Taildrops"

    # Ensure the required directories exist.
    mkdir -p "${systemd_dir}" "${taildrop_dir}"

    # Define and create the systemd service file for managing Taildrop file reception.
    create_tailreceive_service "${systemd_dir}" "${taildrop_dir}"

    # Enable and start the service, then display its status.
    systemctl --user daemon-reload
    systemctl --user enable --now tailreceive
    systemctl --user status tailreceive
}

# Creates a systemd service file for Taildrop in the specified systemd directory, targeting the Taildrop directory.
create_tailreceive_service() {
    local systemd_dir=$1
    local taildrop_dir=$2

  cat << EOF > "${systemd_dir}/tailreceive.service"
[Unit]
Description=File Receiver Service for Taildrop

[Service]
UMask=0077
ExecStart=tailscale file get --loop --verbose --conflict=rename "${taildrop_dir}"

[Install]
WantedBy=default.target
EOF
}

# Reloads the systemd daemon, starts the Taildrop service, and checks its status.
reload_systemd_and_start_taildrop_service() {
  systemctl --user daemon-reload
  systemctl --user restart tailreceive
}

# Creates a file if it does not already exist.
create_file_if_not_exists() {
  local file=$1
  if [[ ! -f ${file} ]]; then
    mkdir -p "$(dirname "${file}")"
    touch "${file}"
  fi
}

# Generates a script for sending files via Taildrop.
generate_taildrop_script() {
  local taildrop_script=$1

  create_file_if_not_exists "${taildrop_script}"

  cat << 'EOF' > "${taildrop_script}"
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
EOF
}

# Generates or updates a .desktop file for integrating Taildrop with the KDE service menu.
create_desktop_file() {
  local taildrop_script=$1
  local desktop_file_path=$2

  create_file_if_not_exists "${desktop_file_path}"

  # Create or update the .desktop file
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
Icon=${HOME}/Themes/Icons/tailscale.png
Exec=${HOME}/.config/dolphin_service_menus_creator/${taildrop_script}.sh %F

[Desktop Action default_action]
X-KDE-Priority=TopLevel
X-KDE-Submenu=
Name=Send via Taildrop
Icon=${HOME}/Themes/Icons/tailscale.png
Exec=${HOME}/.config/dolphin_service_menus_creator/${taildrop_script}.sh %F
EOF
}

# Main function
main() {
  local taildrop_script="${HOME}/.config/dolphin_service_menus_creator/taildrop_script.sh"
  local desktop_file_path="${HOME}/.local/share/kservices5/ServiceMenus/Taildrop.desktop"

  download_icon
  generate_taildrop_script "${taildrop_script}"
  create_desktop_file "${taildrop_script}" "${desktop_file_path}"
  setup_taildrop_service
  reload_systemd_and_start_taildrop_service
}

main "$@"
