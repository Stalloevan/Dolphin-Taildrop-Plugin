# Taildrop Bash Script

This bash script and accompanying desktop file are designed to facilitate file transfers over the [Tailscale](https://tailscale.com/) network. It leverages Tailscale's features interactively choose a device from the network and securely transfer files to that chosen device via the Taildrop service.

## Prerequisites

- [Tailscale](https://tailscale.com/download/linux) installed and configured on your system.

## Usage

1. Add the script to the '.Config' folder in your home directory

2. Make sure the script is executable

3. Add the desktop file to the '.local/share/kservices5/ServiceMenus/' folder in your home directory

4. Add the icon to a directory of your choosing

5. Refresh Dolphin File Explorer

6. Select the files you would like to transfer

7. The script fetches the Tailscale network status and displays a radiolist with the available friendly device names.

8. Choose a device from the list, and the script will attempt to ping the selected device to verify its online status.

9. If the device is online, the chosen files are transferred to the selected device using the Tailscale network.

10. A notification popup displays the status of the file transfer.

## Features

- **Dynamic Device List:** The script dynamically fetches the Tailscale network status to provide an up-to-date list of available devices.
  
- **Interactive Device Selection:** Users can choose a device interactively from the list for secure file transfers.

- **Real-time Notifications:** The script provides real-time notifications on the success or failure of file transfers.

## Notes

- Ensure Tailscale is properly configured and running before using this script.
- Works best on KDE Plasma.

Feel free to customize the script based on your preferences and requirements. For any issues or improvements, please submit a GitHub issue or pull request :)
