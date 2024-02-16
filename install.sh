#!/usr/bin/env bash

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

# Makes a file executable.
make_executable() {
  local file=$1
  chmod +x "${file}"
}

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
generate_taildrop_service() {
  echo "Setting up Tailscale for Taildrop..."

    # Elevate privileges to configure Tailscale with admin rights.
  sudo tailscale up --operator="${USER}"

  # Define directory for systemd unit files and Taildrop download directory
  local systemd_dir="${HOME}/.config/systemd/user"
  local taildrop_dir="${HOME}/Taildrops"

    # Ensure the required directories exist.
    mkdir -p "${systemd_dir}" "${taildrop_dir}"

    # Define and create the systemd service file for managing Taildrop file reception.
    generate_tailreceive_service "${systemd_dir}" "${taildrop_dir}"

    # Enable and start the service, then display its status.
    systemctl --user daemon-reload
    systemctl --user enable --now tailreceive
    systemctl --user status tailreceive
}

# Creates a systemd service file for Taildrop in the specified systemd directory, targeting the Taildrop directory.
generate_tailreceive_service() {
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

# Generates a script for sending files via Taildrop.
generate_taildrop_script() {
  local taildrop_script=$1

  create_file_if_not_exists "${taildrop_script}"

  cat << 'EOF' > "${taildrop_script}"
#!/usr/bin/env bash

#!/usr/bin/env bash

# Main function
main() {
  # Use associative array to store device status to simplify logic
  declare -A device_status_map
  local status_output
  status_output=$(tailscale status)
  local friendly_name
  local device_list=()

  # Parse and fill associative array with device status
  local line
  while read -r line; do
    friendly_name=$(echo "${line}" | awk '{print $2}')
    if [[ -n "${friendly_name}" ]]; then
      # Directly check connectivity and assign status
      if tailscale ping --timeout=0.01s "${friendly_name}" &>/dev/null; then
        device_status_map["${friendly_name}"]=on
      else
        device_status_map["${friendly_name}"]=off
      fi
    fi
  done <<< "${status_output}"

  # Prepare device list for dialog, marking status
  local name
  for name in "${!device_status_map[@]}"; do
    device_list+=("${name}" "${name}" "${device_status_map[${name}]}")
  done

  # Use kdialog to choose a device
  local chosen_device
  chosen_device=$(kdialog --title 'Taildrop' --radiolist "Choose Device" "${device_list[@]}" --geometry 200x50)

  if [[ -z "${chosen_device}" ]]; then
    echo "No device selected."
    exit 1
  fi

  # Re-check if device is connected before proceeding
  if tailscale ping --timeout=0.01s "${chosen_device}" &>/dev/null; then
    local list_names=""
    # Process each file provided as argument
    local file
    for file in "$@"; do
      if [[ -f "${file}" ]]; then # Ensure it's a file
        tailscale file cp "${file}" "${chosen_device}":
        # Append file name to list for notification
        list_names+="${file##*/}, "
      fi
    done

    # Trim trailing comma and space
    list_names="${list_names%, }"

    # Show notification of delivered files
    kdialog --title 'Taildrop' --passivepopup "Files delivered: ${list_names}" --icon "${HOME}/Themes/Icons/tailscale.png"
  else
    kdialog --title 'Taildrop' --passivepopup "Device '${chosen_device}' is offline" --icon "${HOME}/Themes/Icons/tailscale.png"
  fi
}

main "$@"
EOF
  make_executable "${taildrop_script}"
}

# Generates or updates a .desktop file for integrating Taildrop with the KDE service menu.
generate_dot_desktop_file() {
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
Exec=${taildrop_script} %F

[Desktop Action default_action]
X-KDE-Priority=TopLevel
X-KDE-Submenu=
Name=Send via Taildrop
Icon=${HOME}/Themes/Icons/tailscale.png
Exec=${taildrop_script} %F
EOF
}

# Main function
main() {
  local taildrop_script="${HOME}/.config/dolphin_service_menus_creator/taildrop_script.sh"
  local desktop_file_path="${HOME}/.local/share/kservices5/ServiceMenus/Taildrop.desktop"

  download_icon
  generate_taildrop_script "${taildrop_script}"
  generate_dot_desktop_file "${taildrop_script}" "${desktop_file_path}"
  generate_taildrop_service
  reload_systemd_and_start_taildrop_service
}

main "$@"
