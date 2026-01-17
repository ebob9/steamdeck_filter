#!/bin/bash
#
# If you want to download this remotely on the steamdeck, enable SSH with:
# `sudo systemctl start sshd`
#
# This script expects superuser privileges
#
# Thanks to crono141 from this redit post for the idea:
# https://www.reddit.com/r/SteamDeck/comments/zpuret/my_post_update_installation_script/
#

# Enable error tracing
set -o errtrace

# Function to check if the script is run as root
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root." >&2
        exit 1
    fi
}

# Function to ensure required files exist in the current directory
ensure_required_files() {
    local required_files=("10-update-dnsmasq.sh" "dnsmasq.conf" "networkmanager-dns.conf" "no-stub.conf")
    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -ne 0 ]]; then
        echo "Error: The following required files are missing in the current directory:" >&2
        for file in "${missing_files[@]}"; do
            echo " - $file" >&2
        done
        exit 1
    fi
}

# Function to check the exit status of the last command and print it
check_error() {
    local last_command="${BASH_COMMAND}"  # Get the last executed command
    local silent_mode="${1:-false}"  # Default to "false" if no argument is provided

    if [[ $? -eq 0 ]]; then
        if [[ "$silent_mode" != "true" ]]; then
            echo -e "OK\n"
        fi
    else
        echo -e "ERROR\nError: Command '$last_command' failed. Exiting." >&2
        exit 1
    fi
}

# start real work.
echo -n "# Checking environment.. "
ensure_root
check_error true
ensure_required_files
check_error


# unlock FS
echo -n "# Unlocking FS.. "
steamos-readonly disable
check_error

#initialize keyring
echo -n "# Init/Setup of pacman.. "
pacman-key --init
check_error true
pacman-key --populate archlinux holo
#check_error true
#pacman-key --refresh-keys
check_error

# install DNSMASQ
echo -n "# Installing dnsmasq.. "
pacman -Syu --noconfirm dnsmasq
check_error true
sudo mkdir -p /etc/systemd/system/dnsmasq.service.d/
sudo tee /etc/systemd/system/dnsmasq.service.d/override.conf <<EOF
[Unit]
# Ensure dnsmasq wins the race for Port 53
Before=systemd-resolved.service
Conflicts=systemd-resolved.service
EOF
check_error

#config dnsmasq
echo -n "# Applying dnsmasq.conf.. "
cat ./dnsmasq.conf > /etc/dnsmasq.conf
check_error


# disable resolved
echo -n "# Disabling system-resolved.. "
systemctl stop systemd-resolved
check_error true
systemctl disable --now systemd-resolved
check_error


# toast /etc/resolv.conf
echo -n "# Unlinking /etc/resolv.conf.. "
rm -f /etc/resolv.conf
check_error

echo -n "# Asking systemd-resolved to get out of the way.. "
sudo sed -i '/^#\?DNSStubListener=/c\DNSStubListener=no' /etc/systemd/resolved.conf
check_error true
grep -q '^#\?DNSStubListener=' /etc/systemd/resolved.conf || echo 'DNSStubListener=no' | sudo tee -a /etc/systemd/resolved.conf
check_error true
sudo mkdir -p /etc/systemd/resolved.conf.d/
check_error true
cat ./no-stub.conf > /etc/systemd/resolved.conf.d/no-stub.conf
check_error

# recreate /etc/resolv.conf
echo -n "# Recreating /etc/resolv.conf.. "
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
check_error

# reconfig NetworkManager
echo -n "# Reconfiguring NetworkManager.. "
cat ./networkmanager-dns.conf > /etc/NetworkManager/conf.d/dns.conf
check_error true
# NetworkManager hook
mkdir -p /etc/NetworkManager/dispatcher.d
check_error true
cat ./10-update-dnsmasq.sh > /etc/NetworkManager/dispatcher.d/10-update-dnsmasq
check_error true
chmod 755 /etc/NetworkManager/dispatcher.d/10-update-dnsmasq
check_error

# restart services
echo -n "# Restarting Services.. "
# ask systemd to stop just in case.
systemctl stop systemd-resolved
check_error true
sudo systemctl enable --now dnsmasq
check_error true
sudo systemctl restart NetworkManager
check_error

echo -n "# Re-locking FS.. "
#RE-LOCK FILESYSTEM
steamos-readonly enable
check_error

echo "# Completed Successfully!"
