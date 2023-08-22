#!/bin/bash
set -e

# Configuration
VSCODE_EXTENSIONS=(
rocketseat.theme-omni
esbenp.prettier-vscode
dbaeumer.vscode-eslint
golang.go
ms-vscode.cmake-tools
HashiCorp.terraform
britesnow.vscode-toggle-quotes
mitchdenny.ecdc
ms-kubernetes-tools.vscode-kubernetes-tools
oderwat.indent-rainbow
redhat.ansible
signageos.signageos-vscode-sops
usernamehw.errorlens
fcrespo82.markdown-table-formatter
ms-vscode-remote.remote-ssh
ms-vscode-remote.remote-ssh-edit
ms-vscode-remote.remote-containers
)

# Colors
BLUE='\033[1;34m'
NC='\033[0m'

read -p "System username: " USER_NAME
read -p "Git Username: " GIT_NAME
read -p "Git Email: " GIT_EMAIL

# The script begins here.
pac() {
  pacman -Syu --noconfirm --needed $1
}

# Utilities
echo -e "\n${BLUE}###Installing Base Packages###${NC}\n"
pac "base-devel sudo vim git cmake imv linux-headers noto-fonts-emoji openssh neofetch btop bat stow wget curl bind wl-clipboard otf-font-awesome podman buildah skopeo cni-plugins fuse-overlayfs slirp4netns man-db man-pages"
pac "bluez bluez-utils alsa-utils pipewire pipewire-alsa pipewire-pulse blueberry pavucontrol zip unzip unrar"

# Paru, fonts and other AUR tools
echo -e "\n${BLUE}###Installing Paru###${NC}\n"
git clone https://aur.archlinux.org/paru.git
chown -R $USER_NAME paru
sudo --user=$USER_NAME sh -c "cd /paru && makepkg -si"

echo -e "\n${BLUE}###Installing AUR Packages###${NC}\n"
sudo --user=$USER_NAME sh -c "paru -S --noconfirm --needed ttf-iosevka ttf-meslo visual-studio-code-bin brave-bin kitty discord ffmpeg ffmpegthumbnailer thunar thunar-archive-plugin tumbler spotify direnv sops age tldr python-i3ipc"

# Sway & desktop tools
echo -e "\n${BLUE}###Installing Hyprland###${NC}\n"
sudo --user=$USER_NAME sh -c "paru -S --noconfirm --needed hyprland kitty waybar hyprpaper hyprpicker swaylock-effects swayidle wofi wlogout sddm mako thunar ttf-jetbrains-mono-nerd noto-fonts-emoji polkit-gnome python-requests starship swappy grim slurp pamixer brightnessctl gvfs bluez bluez-utils lxappearance xfce4-settings dracula-gtk-theme dracula-icons-git xdg-desktop-portal-hyprland"

# Environment
echo "LIBSEAT_BACKEND=seatd" >> /etc/environment
echo "EDITOR=vim" >> etc/environment

# Services
echo -e "\n${BLUE}###Enabling Networkd###${NC}\n"
systemctl enable systemd-networkd.service
echo -e "\n${BLUE}###Enabling Resolved###${NC}\n"
systemctl enable systemd-resolved.service
echo -e "\n${BLUE}###Enabling DHCP###${NC}\n"
systemctl enable dhcpcd.service
echo -e "\n${BLUE}###Enabling Seatd###${NC}\n"
systemctl enable seatd.service
echo -e "\n${BLUE}###Enabling SSH###${NC}\n"
systemctl enable sshd.service

# Dotfiles symlink farm
echo -e "\n${BLUE}###Configuring User Settings###${NC}\n"
cd /home/$USER_NAME/.dotfiles
mkdir -p /home/$USER_NAME/.config
mkdir -p /home/$USER_NAME/.images
stow --adopt -vt /home/$USER_NAME/.config .config
stow --adopt -vt /home/$USER_NAME/.images .images
echo -e '\neval "$(starship init bash)"' >> /home/$USER_NAME/.bashrc
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME

# VSCode VSCODE_EXTENSIONS
echo -e "\n${BLUE}###Configuring VSCode###${NC}\n"
for i in ${VSCODE_EXTENSIONS[@]}; do
  sudo --user=$USER_NAME sh -c "code --force --install-extension $i"
done

# Git
echo -e "\n${BLUE}###Configuring Git###${NC}\n"
git config --global init.defaultbranch main
git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL

echo -e "\n${BLUE}***The script has finished.***\n\n***Please reboot your PC using 'reboot' command.***${NC}"
exit
