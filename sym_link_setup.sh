#!/bin/bash
# This line tells the system to use bash as the interpreter for the script

# Create necessary directories if they don't exist
mkdir -p ~/.config               # Creates .config directory if it doesn't exist
mkdir -p ~/.dotfiles/.config     # Creates .dotfiles/.config if it doesn't exist
# The -p flag creates parent directories if they don't exist

# Function to backup existing config
backup_config() {
    local config_dir="$1"    # Takes the directory name as an argument
    local backup_dir="$HOME/.config_backup/$(date +%Y%m%d)"  
    # Creates a backup directory with today's date (e.g., 20241122)
    
    # Check if config exists and is NOT a symlink
    if [ -e "$HOME/.config/$config_dir" ] && [ ! -L "$HOME/.config/$config_dir" ]; then
        # -e checks if file/directory exists
        # -L checks if it's a symbolic link
        echo "Backing up existing $config_dir configuration..."
        mkdir -p "$backup_dir"  # Create backup directory
        mv "$HOME/.config/$config_dir" "$backup_dir/"  # Move existing config to backup
    fi
}

# Function to create symlink
create_symlink() {
    local config_dir="$1"    # Takes the directory name as an argument
    
    # Check if the source directory exists in dotfiles
    if [ -d "$HOME/.dotfiles/.config/$config_dir" ]; then
        # -d checks if directory exists
        echo "Creating symlink for $config_dir..."
        # Create symbolic link: ln -sf <source> <destination>
        ln -sf "$HOME/.dotfiles/.config/$config_dir" "$HOME/.config/$config_dir"
    fi
}

# Get list of directories in .config
echo "Getting list of configurations..."
cd "$HOME/.dotfiles/.config" || exit 1  
# Change to dotfiles directory, exit if fails

# Create array of directory names
# mapfile is known as 'readarray'
mapfile -t config_dirs < <(ls -d */ 2>/dev/null | cut -f1 -d'/')
# ls -d */          : List only directories
# cut -f1 -d'/'    : Remove trailing slash
# 2>/dev/null      : Suppress errors
# mapfile -t       : Read into array

# Process each configuration directory
for dir in "${config_dirs[@]}"; do     # Loop through array of directories
    echo "Processing $dir..."
    backup_config "$dir"               # Backup existing config if needed
    create_symlink "$dir"             # Create symlink
done

echo "Configuration setup complete!"

# Optional: List all created symlinks
echo -e "\nCreated symlinks:"
ls -la ~/.config/ | grep '^l'         # Show only symbolic links
# ls -la          : List all files in long format
# grep '^l'       : Filter lines starting with 'l' (symlinks)
