#!/bin/bash

# Run tailscale status and extract friendly names
status_output=$(tailscale status)
friendly_name_list=()
device_list=()

# Process each line in the output
while IFS= read -r line
do
    # Extract friendly name
    friendly_name=$(echo "$line" | awk '{print $2}')
    friendly_name_list+=("$friendly_name")
done <<< "$status_output"

#echo "$status"
echo "${friendly_name_list[@]}"
echo ""

# Only include online external devices in the list
for name in "${friendly_name_list[@]}"
do
    echo "$name"
    # Check to see if the device is connected
    ping=$(tailscale ping --timeout .01s "$name")

    if [[ $ping == *pong* ]]; then
        # Add the friendly name to the list with 'on' state
        device_list+=("$name" "$name" on)
    fi
done
echo "$device_list"
echo ""

# Display popup to choose device from list
chosen_device=$(kdialog --title 'Taildrop' --radiolist "Choose Device" "${device_list[@]}" --geometry 200x50)

# Check again to see if device is connected
    ping=$(tailscale ping --timeout .01s "$chosen_device")
if [[ $ping == *pong* ]]; then

# Loop through selected items in Dolphin
for file in "$@"
do
    # Execute taildrop command to chosen device
    tailscale file cp "$file" "$chosen_device":

    # Extract the short file name using parameter expansion
    short_name="${file##*/}"

    # Check if there are multiple entries in the array
    if [ "$file" != "${@: -1}" ]; then
        # If not the last iteration, add ', ' to the short_name
        list_name="$short_name"', '
    else
        # If there is only one entry, use it directly
        list_name="$short_name"
    fi
    # Add the short file name to the array
    list+=("$list_name")
done

    # Show notification
    kdialog --title 'Taildrop' --passivepopup "$(echo ${list[@]} 'sent successfully')" --icon file:///home/e/Themes/Icons/tailscale.png
else
    kdialog --title 'Taildrop' --passivepopup "$(echo ${list[@]} 'not delivered')" --icon file:///home/e/Themes/Icons/tailscale.png
fi
