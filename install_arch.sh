#!/usr/bin/env bash
set -e

# Variables

##  Partitioning
DEVICE="/dev/nvme0n1"
NVME=yes
FIRMWARE_MODE=uefi # uefi, bios, auto
SWAP_SIZE=8192MiB

##  Time and date
TIMEZONE="America/Denver"

##  Network and connectivity
REFLECTOR=yes
REFLECTOR_COUNTRY="US"

##  Graphics Drivers
DRIVER="amd" # nouveau, amd, intel

##  Kernel
KERNEL="linux" # linux, linux-hardened, linux-zen, linux-lts

##  Locale
LOCALE="en_US.UTF-8"
LOCALE_GEN="en_US.UTF-8 UTF-8"
KEYMAP="us"

##  Hostname
HOSTNAME=laptop01
DOMAIN=prymal.linux

##  Bootloader
BOOTLOADER="systemd"

##  Colors
BLUE='\033[1;34m'
NC='\033[0m'

pac() {
  arch-chroot /mnt pacman -Syu --noconfirm --needed $1
}

echo -e "\n${BLUE}.dotfiles-hyprland Installation"
echo -e "       ${NC}by PrymalInstynct"
echo -e "${BLUE}Inspired by SocketByte"
echo -e " ${NC}"
read -p "Do you want to continue? [y/N] " yn
case $yn in
  [Yy]*)
    ;;
  [Nn]*)
    exit
    ;;
  *)
    exit
    ;;
esac
echo
read -p "Set a username: " USER_NAME
read -s -p "Set the user password: " USER_PASSWORD
echo
read -s -p "Set the root password: " ROOT_PASSWORD
echo

# Check for UEFI firmware mode, otherwise fallback to legacy BIOS
if [ -e "/sys/firmware/efi/efivars" ]; then
  PARTITION_MODE=uefi
else
  PARTITION_MODE=bios
fi

#echo -e "\n${BLUE}###Starting DHCP###${NC}\n"
#systemctl start dhcpcd.service
#sleep 10

echo -e "\n${BLUE}###Setting NTP###${NC}\n"
loadkeys $KEYMAP
timedatectl set-ntp true
timedatectl set-timezone $TIMEZONE

echo -e "\n${BLUE}###Partitioning & Mounting Disks###${NC}\n"
if [ -d /mnt/boot/efi ]; then
  umount /mnt/boot/efi
  umount /mnt
fi
for v_partition in $(parted -s ${DEVICE} print|awk '/^ / {print $1}')
do
  parted -s $DEVICE rm ${v_partition}
done

PART_PRIMARY=""
if [ $PARTITION_MODE = uefi ]; then
  parted -s $DEVICE "mklabel gpt mkpart efi fat32 1MiB 261MiB mkpart swap linux-swap 261MiB $SWAP_SIZE mkpart primary ext4 $SWAP_SIZE 100% set 1 esp on"
  if [ $NVME = yes ]; then
    PART_PRIMARY="${DEVICE}p3"
  else
    PART_PRIMARY="${DEVICE}3"
  fi
else
  parted -s $DEVICE "mklabel msdos mkpart primary ext4 4MiB 512MiB mkpart primary ext4 512MiB 100% set 1 boot on"
  if [ $NVME = yes ]; then
    PART_PRIMARY="${DEVICE}p2"
  else
    PART_PRIMARY="${DEVICE}2"
  fi
fi
if [ $NVME = yes ]; then
  PART_BOOT="${DEVICE}p1"
  PART_SWAP="${DEVICE}p2"
else
  PART_BOOT="${DEVICE}1"
  PART_SWAP="${DEVICE}2"
fi

mkfs.fat -F32 $PART_BOOT

if [ $PARTITION_MODE = uefi ]; then
  mkswap $PART_SWAP
fi

mkfs.ext4 $PART_PRIMARY

mount $PART_PRIMARY /mnt

if [ $PARTITION_MODE = uefi ]; then
  swapon $PART_SWAP
fi

echo -e "\n${BLUE}###Locating Fastest Mirrors###${NC}\n"
if [ $REFLECTOR = yes ]; then
  pacman -Sy --noconfirm --needed "reflector"
  reflector --country $REFLECTOR_COUNTRY --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
fi

echo -e "\n${BLUE}###Installing Base OS###${NC}\n"
pacstrap /mnt base base-devel $KERNEL linux-firmware

echo -e "\n${BLUE}###Generating FSTab###${NC}\n"
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "\n${BLUE}###Setting Timezone###${NC}\n"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
arch-chroot /mnt hwclock --systohc

echo -e "\n${BLUE}###Setting Locale###${NC}\n"
echo "${LOCALE_GEN}" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=${LOCALE}" > /mnt/etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /mnt/etc/vconsole.conf

echo -e "\n${BLUE}###Setting Hostname###${NC}\n"
echo "${HOSTNAME}.${DOMAIN}" > /mnt/etc/hostname
echo "127.0.0.1 localhost\n::1       localhost\n127.0.1.1 ${HOSTNAME}.${DOMAIN} ${HOSTNAME}.${DOMAIN}" > /mnt/etc/hosts

echo -e "\n${BLUE}###Installing Video Driver###${NC}\n"
case $DRIVER in
  "nouveau")
    pac "mesa"
    ;;
  "amd")
    pac "mesa vulkan-radeon xf86-video-amdgpu libva-mesa-driver mesa-vdpau"
    ;;
  "intel")
    pac "mesa vulkan-intel xf86-video-intel"
    ;;
esac

echo -e "\n${BLUE}###Configuring Users###${NC}\n"
printf "$ROOT_PASSWORD\n$ROOT_PASSWORD" | arch-chroot /mnt passwd

arch-chroot /mnt useradd -m $USER_NAME
arch-chroot /mnt groupadd -r seat
arch-chroot /mnt usermod -aG seat $USER_NAME

printf "$USER_PASSWORD\n$USER_PASSWORD" | arch-chroot /mnt passwd $USER_NAME

echo "${USER_NAME} ALL=(ALL) ALL" >> /mnt/etc/sudoers

arch-chroot /mnt chown -R $USER_NAME /home/$USER_NAME

echo -e "\n${BLUE}###Configuring GRUB/BIOS/UEFI###${NC}\n"
pac "grub efibootmgr amd-ucode"

if [ $PARTITION_MODE = uefi ]; then
  mkdir /mnt/boot/efi
  arch-chroot /mnt mount ${PART_BOOT} /boot/efi
  arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi
else
  arch-chroot /mnt grub-install --target=i386-pc ${DEVICE}
fi

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

arch-chroot /mnt mkinitcpio -P

echo -e "\n${BLUE}###Configuring Extra Software###${NC}\n"
pac "vim dhcpcd openssh git kitty-terminfo iwd"

# Continue the installation.
echo -e "\n${BLUE}###Executing Post Installation###${NC}\n"
cp .dotfiles-hyprland/install_hyprland.sh /mnt/
cp -r .dotfiles-hyprland /mnt/home/$USER_NAME/.dotfiles
arch-chroot /mnt chmod +x install_hyprland.sh
arch-chroot /mnt ./install_hyprland.sh
