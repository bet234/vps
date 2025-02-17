#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Ask for CRD Code early
read -p "Paste the CRD command here: " CRD

# Default user credentials
USERNAME="user"
PASSWORD="root"
PIN="123456"

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Create and configure user
create_user() {
    echo "[+] Creating user: $USERNAME"
    useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
    usermod -aG sudo "$USERNAME"
    
    # Allow sudo without password
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
    # Set correct ownership for home directory
    chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

    echo "[+] User '$USERNAME' created with password '$PASSWORD'"
}

# Install required packages
install_packages() {
    echo "[+] Updating and installing packages..."
    apt update && apt upgrade -y
    apt install -y wget curl xvfb xserver-xorg-video-dummy xbase-clients \
                   python3-packaging python3-psutil python3-xdg libgbm1 libutempter0 \
                   libfuse2 nload ffmpeg gpac fonts-lklug-sinhala \
                   xfce4 desktop-base xfce4-terminal xfce4-session xscreensaver \
                   dbus-x11 dbus firefox wine64

    # Remove gnome-terminal to avoid conflicts
    apt remove -y gnome-terminal
}

# Install Chrome Remote Desktop
install_crd() {
    echo "[+] Installing Chrome Remote Desktop..."
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb || apt install -f -y
    rm chrome-remote-desktop_current_amd64.deb

    echo "[+] Configuring CRD for user..."
    adduser "$USERNAME" chrome-remote-desktop
    echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session
    systemctl disable lightdm.service
    
    # Start CRD with PIN
    su - "$USERNAME" -c "$CRD --pin=$PIN"
    systemctl enable --now chrome-remote-desktop
    
    echo "[+] Chrome Remote Desktop setup complete"
}

# Setup storage directory
setup_storage() {
    echo "[+] Setting up storage..."
    mkdir -p /storage
    chmod 770 /storage
    chown "$USERNAME":"$USERNAME" /storage
    ln -s /storage /home/"$USERNAME"/storage
}

# Run all functions
create_user
install_packages
install_crd
setup_storage

echo "[✔] Setup complete. Use Chrome Remote Desktop to connect."
