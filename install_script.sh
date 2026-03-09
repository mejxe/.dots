#!/usr/bin/env bash

# --- Configuration ---
DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
PACKAGES=("git" "stow" "neovim" "zsh" "kitty")

# --- Colors for output ---
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}--- Starting Arch Bootstrap ---${NC}"

# 1. Update System
sudo pacman -Syu --noconfirm

# 2. Install Official Packages
echo -e "${YELLOW}Installing official packages...${NC}"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# 3. Install Yay (AUR Helper) if not present
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay (AUR helper)...${NC}"
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm
    cd - || exit
fi

# 4. Clone Dotfiles
if [ ! -d "$DOTFILES_DIR" ]; then
    echo -e "${YELLOW}Cloning dotfiles...${NC}"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo -e "${YELLOW}Dotfiles directory already exists. Skipping clone.${NC}"
fi

# 5. Stow Dotfiles
echo -e "${YELLOW}Stowing configurations...${NC}"
cd "$DOTFILES_DIR" || exit

# Example: Stowing specific folders.
# Use 'stow */' to do everything, but I prefer being explicit:
for folder in zsh nvim tmux; do
    if [ -d "$folder" ]; then
        # -R (restow) handles updates; --adopt handles existing files
        stow -R "$folder"
        echo "Stowed $folder"
    fi
done

echo -e "${YELLOW}--- Setup Complete! ---${NC}"
