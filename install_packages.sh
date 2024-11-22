#!/bin/bash

# Define ANSI color codes for terminal output formatting
# These make the output more readable and highlight different message types
GREEN='\033[0;32m'   # Used for general information
YELLOW='\033[1;33m'  # Used for warnings
RED='\033[0;31m'     # Used for errors
NC='\033[0m'         # Resets color back to terminal default

# Logging functions for consistent message formatting throughout the script
# Each function prefixes the message with a colored status indicator
log() {
    # General information messages in green
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    # Warning messages in yellow
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    # Error messages in red
    echo -e "${RED}[ERROR]${NC} $1"
}

# Define base packages that come with a standard Arch Linux installation
# These packages will be skipped during installation to avoid redundancy
declare -a base_packages=(
    "base"           # Core package group
    "base-devel"     # Development tools group
    "linux"          # Linux kernel
    "linux-firmware" # Firmware files for Linux
    "networkmanager" # Network connection manager
    "efibootmgr"     # EFI boot manager
)

# Function to check if a package is in the base_packages array
# Returns 0 (true) if package is found, 1 (false) if not
is_base_package() {
    local package=$1  # Package name to check
    for base_pkg in "${base_packages[@]}"; do
        if [[ "$package" == "$base_pkg" ]]; then
            return 0  # Package found in base_packages
        fi
    done
    return 1  # Package not found in base_packages
}

# Function to install the AUR helper 'yay' if it's not already installed
install_yay() {
    # Check if yay is already installed
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        # Clone yay repository
        git clone https://aur.archlinux.org/yay.git
        # Change to yay directory or exit if failed
        cd yay || exit 1
        # Build and install yay
        makepkg -si --noconfirm
        # Clean up by removing the cloned repository
        cd .. && rm -rf yay
    fi
}

# Function to install packages from the official repositories
install_packages() {
    local pkg_list=$1          # File containing list of packages
    local skip_count=0         # Counter for skipped packages
    local install_count=0      # Counter for installed packages
    
    while IFS= read -r package; do
        # Skip empty lines and comments (lines starting with #)
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        
        # Skip if package is in base_packages array
        if is_base_package "$package"; then
            warn "Skipping base package: $package"
            ((skip_count++))
            continue
        fi
        
        # Skip if package is already installed
        if pacman -Qi "$package" &> /dev/null; then
            warn "Package already installed: $package"
            ((skip_count++))
            continue
        fi
        
        # Install package if it hasn't been skipped
        log "Installing: $package"
        sudo pacman -S --needed --noconfirm "$package"
        ((install_count++))
    done < "$pkg_list"
    
    # Report installation statistics
    log "Packages skipped: $skip_count"
    log "Packages installed: $install_count"
}

# Function to install packages from the AUR
install_aur_packages() {
    local aur_list=$1     # File containing list of AUR packages
    local aur_count=0     # Counter for installed AUR packages
    
    while IFS= read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        
        # Skip if package is already installed
        if pacman -Qi "$package" &> /dev/null; then
            warn "AUR package already installed: $package"
            continue
        }
        
        # Install AUR package using yay
        log "Installing AUR package: $package"
        yay -S --needed --noconfirm "$package"
        ((aur_count++))
    done < "$aur_list"
    
    # Report number of AUR packages installed
    log "AUR packages installed: $aur_count"
}

# Function to setup and configure the desktop environment
setup_desktop_environment() {
    log "Setting up desktop environments..."
    
    # Configure display manager (GDM)
    if systemctl is-enabled gdm &> /dev/null; then
        warn "GDM is already enabled"
    else
        log "Enabling GDM..."
        sudo systemctl enable gdm
    fi
    
    # Configure i3 window manager
    # Create .xinitrc if it doesn't exist
    if [ ! -f ~/.xinitrc ]; then
        log "Creating .xinitrc for i3..."
        echo "exec i3" > ~/.xinitrc
    fi
    
    # Setup i3 configuration
    if [ ! -d ~/.config/i3 ]; then
        log "Creating i3 config directory..."
        mkdir -p ~/.config/i3
        # Copy default i3 config as starting point
        cp /etc/i3/config ~/.config/i3/config
    fi
    
    # List of essential services to enable and start
    local services=("NetworkManager" "pipewire" "pipewire-pulse")
    
    # Enable and start each service
    for service in "${services[@]}"; do
        # Enable service if not already enabled
        if systemctl is-enabled "$service" &> /dev/null; then
            warn "$service is already enabled"
        else
            log "Enabling $service..."
            sudo systemctl enable "$service"
        fi
        
        # Start service if not already running
        if ! systemctl is-active "$service" &> /dev/null; then
            log "Starting $service..."
            sudo systemctl start "$service"
        fi
    done
}

# Main function that orchestrates the entire installation process
main() {
    log "Starting installation process..."
    
    # Update package databases
    log "Updating package databases..."
    sudo pacman -Sy
    
    # Ensure yay is installed for AUR access
    install_yay
    
    # Install packages from official repositories
    log "Installing official packages..."
    install_packages "pkglist.txt"
    
    # Install packages from AUR
    log "Installing AUR packages..."
    install_aur_packages "aurpkglist.txt"
    
    # Setup desktop environment
    setup_desktop_environment
    
    # Installation complete
    log "Installation complete!"
    log "Please reboot your system to ensure all changes take effect."
}

# Execute main function to start the installation process
main
