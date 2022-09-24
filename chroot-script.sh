#!bin/sh

if ! [ $timezone ]
then
  timezone="Europe/Lisbon"
fi

ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
sed -i "/^#en_US.UTF-8/ cen_US.UTF-8 UTF-8" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

if ! [ $hostname ]
then
  hostname="arch"
fi

echo $hostname >> /etc/hostname

if ! [ $editor ]
then
  editor="neovim"
fi

pacman --noconfirm -Sy efibootmgr $editor networkmanager base-devel git




if [ $cpu ]
then
  pacman --noconfirm -S $cpu-ucode
fi

bootctl install

echo "default  arch.conf 
timeout  4 
console-mode max 
editor  no" > /boot/loader/loader.conf
 
echo "title  Arch Linux 
linux  /vmlinuz-$kernel" > /boot/loader/entries/arch.conf
if [ $cpu ]
then
  echo "initrd  /$cpu-ucode.img" >> /boot/loader/entries/arch.conf
fi
echo "initrd  /initramfs-$kernel.img
options  root=PART$(cat /etc/fstab | grep 'UUID' | head -n 1 - | awk '{print $1}') rw" >> /boot/loader/entries/arch.conf
 
if [ "$gpu" == "nvidia" ]
then
  echo "options  mitigations=off nvidia-drm.modeset=1" >> /boot/loader/entries/arch.conf
else
  echo "options  mitifations=off nvidia-drm.modeset=1" >> /boot/loader/entries/arch.conf
fi
 
 
echo "title  Arch Linux Fallback 
linux  /vmlinuz-$kernel" > /boot/loader/entries/arch-fallback.conf
if [ $cpu ]
then
  echo "initrd  /$cpu-ucode.img" >> /boot/loader/entries/arch-fallback.conf
fi
echo "initrd  /initramfs-$kernel-fallback.img
options  root=PART$(cat /etc/fstab | grep 'UUID' | head -n 1 - | awk '{print $1}') rw" >> /boot/loader/entries/arch-fallback.conf
 
if [ "$gpu" == "nvidia" ]
then
  echo "options  mitigations=off nvidia-drm.modeset=1" >> /boot/loader/entries/arch-fallback.conf
else
  echo "options  mitifations=off nvidia-drm.modeset=1" >> /boot/loader/entries/arch-fallback.conf
fi
systemctl enable NetworkManager

"[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service" > /etc/pacman.d/hooks/100-systemd-boot.hook

"[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux
Target = systemd

[Action]
Description = Signing Kernel for Secure Boot
When = PostTransaction
Exec = /usr/bin/find /boot -type f ( -name vmlinuz-* -o -name systemd* ) -exec /usr/bin/sh -c 'if ! /usr/bin/sbverify --list {} 2>/dev/null | /usr/bin/grep -q "signature certificates"; then /usr/bin/sbsign --key db.key --cert db.crt --output "$1" "$1"; fi' _ {} ;
Depends = sbsigntools
Depends = findutils
Depends = grep" > /etc/pacman.d/hooks/99-secureboot.hook



if ! [ $rootpw ]
then
  rootpw="root"
fi
if ! [ $username ]
then
  username="user"
fi
if ! [ $userpw ]
then
  userpw="user"
fi

echo "root:$rootpw" | chpasswd
useradd -mg wheel $username
echo "$username:$userpw" | chpasswd
sed -i "/^# %wheel ALL=(ALL:ALL) ALL/ c%wheel ALL=(ALL:ALL) ALL" /etc/sudoers

if ! [ $installtype ] || [ $installtype == "minimal" ]
then
  exit
fi

sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy
pacman --noconfirm -S xorg lib32-mesa noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra pipewire lib32-pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack

case $gpu in 
  nvidia)
    pacman -S --noconfirm --needed lib32-libglvnd lib32-nvidia-utils lib32-vulkan-icd-loader libglvnd nvidia-dkms nvidia-settings vulkan-icd-loader
    ;;
    
  amd)
    pacman -S --noconfirm --needed xf86-video-amdgpu mesa lib32-mesa gamescope lib32-vulkan-icd-loader lib32-vulkan-radeon vulkan-icd-loader vulkan-radeon
    ;;
  
  intel)
    pacman -S --noconfirm --needed mesa lib32-mesa gamescope lib32-vulkan-icd-loader lib32-vulkan-intel vulkan-icd-loader vulkan-intel
    ;;
  
  *)
    pacman -S --noconfirm xf86-video-amdgpu xf86-video-intel xf86-video-nouveau
    ;;
esac


if [ $installtype == "desktop" ]
then
  case $desktop in
    kde)
      pacman -S --noconfirm plasma-pa plasma-nm xdg-desktop-portal-kde kscreen kde-gtk-config breeze-gtk kdeplasma-addons ark sddm konsole dolphin systemsettings plasma-desktop plasma-workspace
      systemctl enable sddm
      ;;
    
    xfce)
      pacman -S --noconfirm xfce4 xfce4-goodies lxdm
      systemctl enable lxdm
      ;;
    
    *)
      pacman -S --noconfirm mutter gnome-shell gnome-session nautilus gnome-control-center gnome-tweaks xdg-desktop-portal-gnome gdm gnome-terminal
      systemctl enable gdm
      ;;
  esac
fi
     
