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

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "User '$username' already exists. Skipping user creation."
    else
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
    fi
}

# Extra storage setup
setup_storage() {
    local username="$1"
    mkdir -p /storage
    chmod 777 /storage
    chown "$username":"$username" /storage
    mkdir -p /home/"$username"/storage
    
    # Check if mount directory exists
    if mountpoint -q /home/"$username"/storage; then
        echo "Storage already mounted."
    else
        mount --bind /storage /home/"$username"/storage
        echo "Storage mounted successfully."
    fi
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
    
    # Handle Chrome Remote Desktop service
    systemctl unmask chrome-remote-desktop.service
    systemctl enable chrome-remote-desktop.service
    systemctl start chrome-remote-desktop.service

    setup_storage "$default_username"

    echo "RDP setup completed"
}

# Main execution
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

create_user
setup_rdp

while true; do sleep 1; done
