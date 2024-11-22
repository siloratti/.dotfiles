#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function for logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Base packages that come with archinstall (we'll skip these)
declare -a base_packages=(
    "base"
    "base-devel"
    "linux"
    "linux-firmware"
    "networkmanager"
    "efibootmgr"
)

# Function to check if package is in base packages
is_base_package() {
    local package=$1
    for base_pkg in "${base_packages[@]}"; do
        if [[ "$package" == "$base_pkg" ]]; then
            return 0
        fi
    done
    return 1
}

# Install yay if not present
install_yay() {
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        git clone https://aur.archlinux.org/yay.git
        cd yay || exit 1
        makepkg -si --noconfirm
        cd .. && rm -rf yay
    fi
}

# Function to install packages
install_packages() {
    local pkg_list=$1
    local skip_count=0
    local install_count=0
    
    while IFS= read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        
        # Skip base packages
        if is_base_package "$package"; then
            warn "Skipping base package: $package"
            ((skip_count++))
            continue
        fi
        
        # Check if package is already installed
        if pacman -Qi "$package" &> /dev/null; then
            warn "Package already installed: $package"
            ((skip_count++))
            continue
        fi
        
        log "Installing: $package"
        sudo pacman -S --needed --noconfirm "$package"
        ((install_count++))
    done < "$pkg_list"
    
    log "Packages skipped: $skip_count"
    log "Packages installed: $install_count"
}

# Function to install AUR packages
install_aur_packages() {
    local aur_list=$1
    local aur_count=0
    
    while IFS= read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        
        # Check if package is already installed
        if pacman -Qi "$package" &> /dev/null; then
            warn "AUR package already installed: $package"
            continue
        }
        
        log "Installing AUR package: $package"
        yay -S --needed --noconfirm "$package"
        ((aur_count++))
    done < "$aur_list"
    
    log "AUR packages installed: $aur_count"
}

# Function to setup desktop environment
setup_desktop_environment() {
    log "Setting up desktop environments..."
    
    # Enable display manager (GDM seems to be your choice based on packages)
    if systemctl is-enabled gdm &> /dev/null; then
        warn "GDM is already enabled"
    else
        log "Enabling GDM..."
        sudo systemctl enable gdm
    fi
    
    # Create i3 xinit configuration
    if [ ! -f ~/.xinitrc ]; then
        log "Creating .xinitrc for i3..."
        echo "exec i3" > ~/.xinitrc
    fi
    
    # Setup i3 config if it doesn't exist
    if [ ! -d ~/.config/i3 ]; then
        log "Creating i3 config directory..."
        mkdir -p ~/.config/i3
        cp /etc/i3/config ~/.config/i3/config
    fi
    
    # Enable essential services
    local services=("NetworkManager" "pipewire" "pipewire-pulse")
    
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &> /dev/null; then
            warn "$service is already enabled"
        else
            log "Enabling $service..."
            sudo systemctl enable "$service"
        fi
        
        if ! systemctl is-active "$service" &> /dev/null; then
            log "Starting $service..."
            sudo systemctl start "$service"
        fi
    done
}

# Main installation process
main() {
    log "Starting installation process..."
    
    # Sync package databases
    log "Updating package databases..."
    sudo pacman -Sy
    
    # Install yay for AUR packages
    install_yay
    
    # Install official packages
    log "Installing official packages..."
    install_packages "pkglist.txt"
    
    # Install AUR packages
    log "Installing AUR packages..."
    install_aur_packages "aurpkglist.txt"
    
    # Setup desktop environment
    setup_desktop_environment
    
    log "Installation complete!"
    log "Please reboot your system to ensure all changes take effect."
}

# Run main function
main
