#!/bin/bash

if [ $username ]
then
  username=user
fi

if [ $userpw ]
then
  userpw=user
fi

pacman -S xorg-xrandr xorg-xinit feh alacritty sxhkd bspwm python-pywal dash zsh git zsh-syntax-highlighting xorg-xsetroot 
su $username -c "chsh -s /bin/zsh && systemctl --user enable pulseaudio && cd && git clone https://github.com/miguelrcborges/archinstallscript.git && mv archinstallscript/autorice/* /home/$username/ && rm -rf archinstallscript && chmod +x /home/$username/.config/bspwm/bspwmrc"