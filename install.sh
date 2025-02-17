#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Ask for CRD Code early
read -p "Paste the CRD command here: " CRD

# Set default username and password
default_username="user"
default_password="root"
pin="123456"

# Function to create user
create_user() {
    echo "Creating User and Setting it up"
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

    echo "User created and configured with username '$username' and no password login"
}

# Extra storage setup
setup_storage() {
    local username="$1" 
    mkdir -p /storage
    chmod 777 /storage
    chown "$username":"$username" /storage
    mkdir -p /home/"$username"/storage

    # Bind mount /storage
    mount --bind /storage /home/"$username"/storage || {
        print_color "red" "Mount failed. Please check the directory and permissions."
        exit 1
    }
}

# Function to install and configure RDP
setup_rdp() {
    echo "Installing dependencies"
    apt update
    add-apt-repository universe -y
    apt install --assume-yes xvfb xserver-xorg-video-dummy xbase-clients python3-packaging python3-psutil python3-xdg libgbm1 libutempter0 libfuse2 nload qbittorrent ffmpeg gpac fonts-lklug-sinhala 

    echo "Installing Desktop Environment"
    apt install --assume-yes xfce4 desktop-base xfce4-terminal xfce4-session
    bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'
    apt remove --assume-yes gnome-terminal
    apt install --assume-yes xscreensaver
    systemctl disable lightdm.service
    apt install --assume-yes dbus-x11 dbus

    echo "Installing Chrome Remote Desktop"
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb
    apt install --assume-yes --fix-broken

    echo "Finalizing"
    adduser "$default_username" chrome-remote-desktop
    
    su - "$default_username" -c "$CRD --pin=$pin"
    service chrome-remote-desktop start
    setup_storage "$default_username"

    print_color "green" "✔ Chrome Remote Desktop setup complete"
}

# Print color function
print_color() {
    color=$1
    shift
    case $color in
        red) echo -e "\033[31m$@\033[0m" ;;
        green) echo -e "\033[32m$@\033[0m" ;;
        yellow) echo -e "\033[33m$@\033[0m" ;;
        blue) echo -e "\033[34m$@\033[0m" ;;
        magenta) echo -e "\033[35m$@\033[0m" ;;
        cyan) echo -e "\033[36m$@\033[0m" ;;
        *) echo "$@" ;;
    esac
}

# Main execution
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

create_user
setup_rdp

# ASCII Art for Completion
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

# Keep script running to allow access via CRD
while true; do sleep 1; done
