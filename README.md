# Taildrop Plugin - Dolphin File Explorer Fork

This bash script is designed to facilitate file transfers over the [Tailscale](https://tailscale.com/) network on Linux/KDE/Dolphin. It leverages Tailscale's features interactively choose a device from the network and securely transfer files to that chosen device via the Taildrop service. 

## Prerequisites

- [Tailscale](https://tailscale.com/download/linux) installed and configured on your system.
- [KDE Plasma](https://tailscale.com/download/linux) installed and configured on your system.

## Usage
`curl -fsSL https://raw.githubusercontent.com/error-try-again/KDE-Dolphin-TailDrop-Plugin/main/install.sh | bash`

## Features

- **Dynamic Device List:** The script dynamically fetches the Tailscale network status to provide an up-to-date list of available devices.
  
- **Interactive Device Selection:** Users can choose a device interactively from the list for secure file transfers.

- **Real-time Notifications:** The script provides real-time notifications on the success or failure of file transfers.
