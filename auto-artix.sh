# checking for sudo/doas (literally every command needs it)
if [ "$(id -u)" -ne 0 ]; then
  echo "You have to run as root (sudo/doas)."
  exit 1
fi

SUDO_USER=`sudo env | grep SUDO_USER | cut -f2 -d=`

echo $SUDO_USER "ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# base install
pacman -Sy
if ! grep -q "\[universe]" /etc/pacman.conf; then
  cat universe.conf >> /etc/pacman.conf
else
  echo "Error: universe repos already added..."
fi
pacman -Sy
pacman-key --init
pacman-key --refresh
yes "" | pacman -Sy artix-archlinux-support
if ! grep -q "\[extra]" /etc/pacman.conf; then
  cat mirrorlist.conf >> /etc/pacman.conf
else
  echo "Error: extra/community repos already added..."
fi
pacman-key --populate archlinux
yes "" | pacman -Syu

# installing dialog (required for this)
sudo pacman -S --noconfirm --needed dialog

# extra software (if you chose no, only git and base-devel gets installed)
if dialog --stdout --title "Extra software" \
          --backtitle "Auto-Artix" \
          --yesno "Do you want an extra software list or not?" 7 60; then
    echo "Going with the full install..."
    words=$(cat package.list)
    tempfile=$(mktemp)
    dialog --checklist "Choose one or more words:" 20 60 10 \
      $(for word in $words; do echo "$word" "$word" ON; done) 2>$tempfile
    choices=$(cat $tempfile)
    for choice in $choices
    do
      if [[ $words =~ (^|[[:space:]])"$choice"($|[[:space:]]) ]]
      then
        echo "You chose '$choice'"
      fi
    done
    rm $tempfile
    
    pacman -S --noconfirm --needed git base-devel $choices
    # installing yay
    sudo -u $SUDO_USER git clone https://aur.archlinux.org/yay.git
    cd yay
    yes "" | sudo -u $SUDO_USER makepkg -si
else
    pacman -S --noconfirm --needed git base-devel
fi

# (my cinnamon key shortcuts)
if dialog --stdout --title "Cinnamon keybindings?" \
          --backtitle "Auto-Artix" \
          --yesno "Do you want to import the Cinnamon keybindings? (This will replace the current settings!)" 7 60; then
    dconf load /org/cinnamon/desktop/keybindings/ < dconf-settings.conf
else
    echo "No shortcuts were imported."
fi
