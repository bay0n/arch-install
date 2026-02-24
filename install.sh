#!/bin/bash
set -e

echo "🚀 Starting Arch i3 setup..."

# -----------------------------
# Variables
# -----------------------------
REPO_DIR="$HOME/arch-install"
TIMESTAMP=$(date +%s)
BACKUP_DIR="$HOME/.config_backup_$TIMESTAMP"

DOTFILES_DIR="$REPO_DIR/dotfiles"
WALLPAPER_SRC="$DOTFILES_DIR/wallpapers"
WALLPAPER_DEST="$HOME/Pictures/wallpapers"

REPO_BACKUP_DEST="$HOME/Pictures/arch-install"

# Ensure repo exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Repository not found! Please clone it first:"
    echo "git clone https://github.com/bay0n/arch-install.git $REPO_DIR"
    exit 1
fi

cd "$REPO_DIR"

# -----------------------------
# Enable multilib
# -----------------------------
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib..."
    sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
fi

# -----------------------------
# Update system
# -----------------------------
sudo pacman -Syu --noconfirm

# -----------------------------
# Install official packages
# -----------------------------
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
    base-devel \
    zed \
    papirus-icon-theme \
    lxappearance

# -----------------------------
# Enable NetworkManager
# -----------------------------
sudo systemctl enable NetworkManager

# -----------------------------
# Install yay if missing
# -----------------------------
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# -----------------------------
# Install AUR packages
# -----------------------------
yay -S --needed --noconfirm \
    catppuccin-gtk-theme \
    spotify \
    lunar-client \
    firedragon-bin \
    discord \
    roficalc

# -----------------------------
# Backup existing config
# -----------------------------
if [ -d "$HOME/.config" ]; then
    echo "Backing up existing config to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$HOME/.config" "$BACKUP_DIR/"
fi

# -----------------------------
# Copy dotfiles
# -----------------------------
rsync -a --backup "$DOTFILES_DIR/" "$HOME/"

# -----------------------------
# Copy wallpapers
# -----------------------------
mkdir -p "$WALLPAPER_DEST"
if [ -d "$WALLPAPER_SRC" ]; then
    echo "Copying wallpapers from dotfiles to $WALLPAPER_DEST..."
    rsync -av --progress "$WALLPAPER_SRC/" "$WALLPAPER_DEST/"
fi

# Backup entire repo in Pictures
echo "Copying entire repo to $REPO_BACKUP_DEST..."
rsync -av --progress "$REPO_DIR/" "$REPO_BACKUP_DEST/"

# -----------------------------
# GTK theme setup
# -----------------------------
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

cat << EOF > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=DejaVu Sans 10
EOF

cat << EOF > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=DejaVu Sans 10
EOF

# -----------------------------
# Smart monitor auto-detect script
# -----------------------------
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

# -----------------------------
# Done
# -----------------------------
echo "✅ Installation complete!"
echo "Reboot and run: startx"
