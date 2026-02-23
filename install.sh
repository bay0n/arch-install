#!/bin/bash
set -e

echo "🚀 Installing your private i3 setup..."

REPO_DIR="$HOME/.arch-i3"
TIMESTAMP=$(date +%s)
BACKUP_DIR="$HOME/.config_backup_$TIMESTAMP"

# Clone repo if not already cloned
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/YOURNAME/arch-i3.git "$REPO_DIR"
fi

cd "$REPO_DIR"

# Enable multilib for Steam (if not already enabled)
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib..."
    sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
fi

# Update system
sudo pacman -Syu --noconfirm

# Install core packages
sudo pacman -S --needed --noconfirm \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    i3-wm \
    i3status \
    kitty \
    rofi \
    picom \
    feh \
    dex \
    xss-lock \
    i3lock \
    networkmanager \
    network-manager-applet \
    pipewire \
    pipewire-pulse \
    steam \
    noto-fonts \
    ttf-dejavu \
    git \
    base-devel

# Enable NetworkManager
sudo systemctl enable NetworkManager

# Install yay if missing
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install AUR packages
yay -S --noconfirm spotify lunar-client firedragon discord

# Backup existing config if present
if [ -d "$HOME/.config" ]; then
    echo "Backing up existing config to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$HOME/.config" "$BACKUP_DIR/"
fi

# Copy dotfiles safely (no overwrite without backup)
rsync -a --backup dotfiles/ "$HOME/"

# Ensure wallpaper directory exists
mkdir -p "$HOME/Pictures/wallpapers"

# Smart monitor auto-detect script
mkdir -p "$HOME/.screenlayout"

cat << 'EOF' > "$HOME/.screenlayout/auto.sh"
#!/bin/bash
MONITORS=$(xrandr | grep " connected" | cut -d" " -f1)

PRIMARY=$(echo "$MONITORS" | head -n1)
SECONDARY=$(echo "$MONITORS" | tail -n +2 | head -n1)

if [ -n "$SECONDARY" ]; then
    xrandr --output "$PRIMARY" --primary --auto \
           --output "$SECONDARY" --auto --right-of "$PRIMARY"
else
    xrandr --output "$PRIMARY" --auto
fi
EOF

chmod +x "$HOME/.screenlayout/auto.sh"

echo "✅ Installation complete."
echo "Reboot and run: startx"
