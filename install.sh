#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Function to print in color
print_color() {
    case "$1" in
        "green") echo -e "\033[32m$2\033[0m" ;;  # Green
        "yellow") echo -e "\033[33m$2\033[0m" ;; # Yellow
        "blue") echo -e "\033[34m$2\033[0m" ;;    # Blue
        "red") echo -e "\033[31m$2\033[0m" ;;     # Red
        "cyan") echo -e "\033[36m$2\033[0m" ;;    # Cyan
        "magenta") echo -e "\033[35m$2\033[0m" ;; # Magenta
        *) echo "$2" ;;                            # Default
    esac
}

# ASCII Art Header with color
print_color "cyan" "###############################################################"
print_color "magenta" "                Welcome to the RDP Setup Script                "
print_color "cyan" "                     ___________________                     "
print_color "magenta" "                    |  ___  ___  ___  |                    "
print_color "magenta" "                    | |   ||   ||   | |                    "
print_color "magenta" "                    | |___||___||___| |                    "
print_color "cyan" "                    |  ___  ___  ___  |                    "
print_color "magenta" "                    | |   ||   ||   | |                    "
print_color "magenta" "                    | |___||___||___| |                    "
print_color "cyan" "                    |_________________|                    "
print_color "cyan" "                Configuring Your RDP Environment             "
print_color "cyan" "###############################################################"
echo ""

# Ask for CRD Code early
print_color "yellow" "-------------------------------------------------------------"
print_color "blue" "                How to Get CRD Command                      "
print_color "yellow" "-------------------------------------------------------------"
echo ""
print_color "green" "1. Go to https://remotedesktop.google.com/headless"
print_color "green" "2. Follow the instructions to install Chrome Remote Desktop."
print_color "green" "3. After installation, you'll receive a CRD command that includes a unique PIN."
print_color "green" "4. Paste the CRD command here to complete the setup:"
read -p "Paste the CRD command here: " CRD

# Set default username and password
default_username="user"
default_password="root"
pin="123456"

# ASCII Art for User Creation with color
print_color "yellow" "-------------------------------------------------------------"
print_color "blue" "                Creating User and Setting Up                "
print_color "yellow" "                        ________                           "
print_color "magenta" "                       |        |                          "
print_color "magenta" "                       |  USER  |                          "
print_color "magenta" "                       |________|                          "
print_color "yellow" "-------------------------------------------------------------"
echo ""

# Function to create user
create_user() {
    print_color "green" "Creating User and Setting it up"
    username="$default_username"
    password="$default_password"

    useradd -m "$username"
    usermod -aG sudo "$username"
    echo "$username:$password" | chpasswd
    sed -i 's|/bin/sh|/bin/bash|g' /etc/passwd

    # Set sudo to not require password
    echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

    # Disable password login
    passwd -d "$username"
    passwd -l "$username"

    # Add PATH update to .bashrc of the new user
    echo 'export PATH=$PATH:/home/$username/.local/bin' >> /home/"$username"/.bashrc
    # Reload .bashrc for the new user
    su - "$username" -c "source ~/.bashrc"

    print_color "green" "User created and configured with username '$username' and no password login"
}

# Extra storage setup
setup_storage() {
    local username="$1" 
    mkdir -p /storage
    chmod 777 /storage
    chown "$username":"$username" /storage
    mkdir -p /home/"$username"/storage
    mount --bind /storage /home/"$username"/storage
}

# ASCII Art for RDP Setup with color
print_color "yellow" "-------------------------------------------------------------"
print_color "blue" "                    Setting Up RDP                         "
print_color "yellow" "                     _________                            "
print_color "magenta" "                    |   RDP   |                           "
print_color "magenta" "                    |  Setup  |                           "
print_color "magenta" "                    |_________|                           "
print_color "yellow" "-------------------------------------------------------------"
echo ""

# Function to install and configure RDP
setup_rdp() {
    print_color "green" "Installing dependencies"
    apt update
    add-apt-repository universe -y
    apt install --assume-yes xvfb xserver-xorg-video-dummy xbase-clients python3-packaging python3-psutil python3-xdg libgbm1 libutempter0 libfuse2 nload qbittorrent ffmpeg gpac fonts-lklug-sinhala 

    print_color "green" "Installing Desktop Environment"
    apt install --assume-yes xfce4 desktop-base xfce4-terminal xfce4-session
    bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'
    apt remove --assume-yes gnome-terminal
    apt install --assume-yes xscreensaver
    systemctl disable lightdm.service
    apt install --assume-yes dbus-x11 dbus

    # Installing Firefox
    print_color "green" "Installing Firefox"
    apt install --assume-yes firefox

    print_color "green" "Installing Chrome Remote Desktop"
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb
    apt install --assume-yes --fix-broken

    print_color "green" "Finalizing"
    adduser "$default_username" chrome-remote-desktop
    
    su - "$default_username" -c "$CRD --pin=$pin"
    service chrome-remote-desktop start
    setup_storage "$default_username"

    print_color "green" "✔ Chrome Remote Desktop setup complete"
}

# ASCII Art for Completion with color and emojis
print_color "yellow" "-------------------------------------------------------------"
print_color "blue" "                       Setup Complete                       "
print_color "yellow" "                        _______                            "
print_color "magenta" "                       |       |                           "
print_color "magenta" "                       | DONE  |                           "
print_color "magenta" "                       |_______|                           "
print_color "yellow" "-------------------------------------------------------------"
echo ""

# Completion message with emojis and link
print_color "cyan" "╔════════════════════════════════════╗"
print_color "cyan" "║  🎉 Setup Complete! Connect using CRD 🎉  ║"
print_color "cyan" "║  Use this link: https://remotedesktop.google.com/access  ║"
print_color "cyan" "╚════════════════════════════════════╝"

# Main execution
if [[ $EUID -ne 0 ]]; then
   print_color "red" "This script must be run as root" 
   exit 1
fi

create_user
setup_rdp

while true; do sleep 1; done
