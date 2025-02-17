#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Colors for styling
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# ASCII Art Banner
echo -e "${CYAN}
██████╗ ██████╗ ██████╗ 
██╔══██╗██╔══██╗██╔══██╗
██║  ██║██████╔╝██║  ██║
██║  ██║██╔══██╗██║  ██║
██████╔╝██║  ██║██████╔╝
╚═════╝ ╚═╝  ╚═╝╚═════╝  
${RESET}"
echo -e "${GREEN}★ Chrome Remote Desktop Setup with Firefox ★${RESET}"
echo

# Instructions to get CRD Code
echo -e "${YELLOW}How to Get Your Chrome Remote Desktop (CRD) Code:${RESET}"
echo -e "${CYAN}1.${RESET} Open this link in your browser: ${BLUE}https://remotedesktop.google.com/headless${RESET}"
echo -e "${CYAN}2.${RESET} Sign in with your Google account."
echo -e "${CYAN}3.${RESET} Click on ${GREEN}'Set up another computer'${RESET} and follow the steps."
echo -e "${CYAN}4.${RESET} Copy the command shown for Debian Linux."
echo -e "${CYAN}5.${RESET} Paste the copied command below when prompted."
echo

# Ask for CRD Code
read -p "$(echo -e ${YELLOW}">>> Paste the CRD command here: "${RESET})" CRD

# Default user credentials
USERNAME="user"
PASSWORD="root"
PIN="123456"

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[✘] This script must be run as root${RESET}"
   exit 1
fi

# Function: Create and configure user
create_user() {
    echo -e "${BLUE}[+] Creating user: $USERNAME${RESET}"
    useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
    usermod -aG sudo "$USERNAME"
    
    # Allow sudo without password
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
    # Disable password login for the new user
    passwd -d "$USERNAME"
    passwd -l "$USERNAME"

    # Add PATH update to .bashrc of the new user
    echo 'export PATH=$PATH:/home/$USERNAME/.local/bin' >> /home/"$USERNAME"/.bashrc
    # Reload .bashrc for the new user
    su - "$USERNAME" -c "source ~/.bashrc"

    echo -e "${GREEN}[✔] User '$USERNAME' created successfully${RESET}"
}

# Function: Install required packages
install_packages() {
    echo -e "${BLUE}[+] Updating and installing packages...${RESET}"
    apt update && apt upgrade -y
    apt install -y wget curl xvfb xserver-xorg-video-dummy xbase-clients \
                   python3-packaging python3-psutil python3-xdg libgbm1 libutempter0 \
                   libfuse2 nload ffmpeg gpac fonts-lklug-sinhala \
                   xfce4 desktop-base xfce4-terminal xfce4-session xscreensaver \
                   dbus-x11 dbus firefox

    # Remove gnome-terminal to avoid conflicts
    apt remove -y gnome-terminal

    echo -e "${GREEN}[✔] Packages installed successfully${RESET}"
}

# Function: Install Chrome Remote Desktop
install_crd() {
    echo -e "${BLUE}[+] Installing Chrome Remote Desktop...${RESET}"
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb || apt install -f -y
    rm chrome-remote-desktop_current_amd64.deb

    echo -e "${BLUE}[+] Configuring CRD for user...${RESET}"
    adduser "$USERNAME" chrome-remote-desktop
    echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session
    systemctl disable lightdm.service
    
    # Start CRD with PIN
    su - "$USERNAME" -c "$CRD --pin=$PIN"
    systemctl enable --now chrome-remote-desktop

    echo -e "${GREEN}[✔] Chrome Remote Desktop setup complete${RESET}"
}

# Run all functions
create_user
install_packages
install_crd

echo -e "${CYAN}
╔════════════════════════════════════╗
║  🎉 ${GREEN}Setup Complete! Connect using CRD${CYAN} 🎉  ║
║  Use this link: ${BLUE}https://remotedesktop.google.com/access${CYAN}  ║
╚════════════════════════════════════╝
${RESET}"
