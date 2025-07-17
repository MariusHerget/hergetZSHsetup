#!/bin/sh

# Ask for machine name
printf "What should this machine be named? "
read MACHINE_NAME

# GUI and additional package lists
GUI_INSTALL="code spotify-client nextcloud-desktop nvtop ntfs-3g fonts-firacode ttf-mscorefonts-installer firefox chromium-browser"
CLI_ADD="build-essential make cmake git 7zip zip gcc g++ e2fsprogs speedtest btop"

# Determine if we have sudo
SUDO=""
SUDO_PERM_AVAIL="FALSE"
if [ "$(id -u)" -ne 0 ]; then
    printf "Do you have sudo permissions on this machine? <y/N> "
    read ANSWER
    ANSWER=${ANSWER:-N}
    case "$ANSWER" in
      [Yy]) SUDO="sudo"; SUDO_PERM_AVAIL="TRUE" ;;
      *) echo "No installations can be performed." ;;
    esac
else
    SUDO_PERM_AVAIL="TRUE"
fi

# If sudo/root available, prepare core install list
if [ "$SUDO_PERM_AVAIL" = "TRUE" ]; then
    INSTALL_PKGS=""

    # zsh
    if ! command -v zsh >/dev/null 2>&1; then
        INSTALL_PKGS="$INSTALL_PKGS zsh"
    else
        echo "ZSH already installed"
    fi

    # curl
    if ! command -v curl >/dev/null 2>&1; then
        INSTALL_PKGS="$INSTALL_PKGS curl"
    else
        echo "CURL already installed"
    fi

    # chsh (util-linux-user)
    if ! command -v chsh >/dev/null 2>&1; then
        INSTALL_PKGS="$INSTALL_PKGS util-linux-user"
    else
        echo "chsh already installed"
    fi

    # common tools
    INSTALL_PKGS="$INSTALL_PKGS trash-cli apt-transport-https ca-certificates wget software-properties-common vim htop tmux"

    # Perform installation if any packages are pending
    if [ -n "$INSTALL_PKGS" ]; then
        if command -v apt >/dev/null 2>&1; then
            $SUDO apt update
            $SUDO apt install -y $INSTALL_PKGS
        elif command -v brew >/dev/null 2>&1; then
            $SUDO brew install $INSTALL_PKGS
        elif command -v yum >/dev/null 2>&1; then
            $SUDO yum install -y $INSTALL_PKGS
        elif command -v zypper >/dev/null 2>&1; then
            $SUDO zypper install -y $INSTALL_PKGS
        else
            echo "No known package manager installed"
            exit 1
        fi
    fi
fi

# Ensure default shell is zsh
if ! echo "$SHELL" | grep -q 'zsh'; then
    $SUDO chsh "$(whoami)" -s "$(command -v zsh)"
fi
echo "\$SHELL -> zsh"

# Install Oh My Zsh
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
    cp "${HOME}/.zshrc" "${HOME}/.zshrc.orig" 2>/dev/null
else
    echo "Oh My Zsh already present."
fi

# Copy custom theme if missing
if [ ! -f "${HOME}/.oh-my-zsh/themes/xxf.zsh-theme" ]; then
    cp ./xxf.zsh-theme "${HOME}/.oh-my-zsh/themes/xxf.zsh-theme"
else
    echo "XXF theme already installed."
fi

# Install user config files
echo "Copying .zshrc and .tmux.conf"
cp .zshrc "${HOME}/.zshrc"
# substitute machine name placeholder
sed -i "s|{{VARIABLE_CUSTOMSERVERNAME}}|$MACHINE_NAME|g" "${HOME}/.zshrc"
cp .tmux.conf "${HOME}/.tmux.conf"

# Source additional config if present
printf "Checking for .aliases… "
if [ -f "./.aliases" ]; then
    printf "\nsource %s/.aliases\n" "$PWD" >> "${HOME}/.zshrc"
    echo "added"
else
    echo "none found"
fi

printf "Checking for .user-conf… "
if [ -f "./.user-conf" ]; then
    TMPFILE=$(mktemp)
    awk -v pwd="$PWD" '
      !done && /source \$ZSH\/oh-my-zsh.sh/ { print "source " pwd "/.user-conf"; done=1 }
      { print }
    ' "${HOME}/.zshrc" > "$TMPFILE" && mv "$TMPFILE" "${HOME}/.zshrc"
    echo "added"
else
    echo "none found"
fi

# Source any other alias files in home
for f in $(ls -A "${HOME}" | grep '\.aliases'); do
    printf "\nsource %s/%s\n" "${HOME}" "$f" >> "${HOME}/.zshrc"
    echo "Added $f"
done

# If root/sudo, append system PATH to zprofile
if [ "$SUDO_PERM_AVAIL" = "TRUE" ]; then
    echo "Inserting PATH into /etc/zsh/zprofile"
    printf 'PATH=%s\nexport PATH\n' "$PATH" | $SUDO tee -a /etc/zsh/zprofile >/dev/null
fi

# Ask about trash alias
printf "Do you want to use trash for rm? <Y/n> "
read ANSWER
ANSWER=${ANSWER:-Y}
case "$ANSWER" in
  [Yy]) printf "\nalias rm='trash'\n" >> "${HOME}/.zshrc" ;;
  *) ;; 
esac

# Additional CLI tools
if [ "$SUDO_PERM_AVAIL" = "TRUE" ]; then
    printf "\nDo you want to install additional CLI tools? <Y/n>\n(%s) " "$CLI_ADD"
    read ANSWER
    ANSWER=${ANSWER:-Y}
    if [ "${ANSWER%?}" = "Y" ] || [ "${ANSWER%?}" = "y" ]; then
        if [ -n "$CLI_ADD" ]; then
            if command -v apt >/dev/null 2>&1; then
                curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | $SUDO bash
                $SUDO apt update
                $SUDO apt install -y $CLI_ADD
            elif command -v brew >/dev/null 2>&1; then
                $SUDO brew install $CLI_ADD
            elif command -v yum >/dev/null 2>&1; then
                curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | $SUDO bash
                $SUDO yum install -y $CLI_ADD
            elif command -v zypper >/dev/null 2>&1; then
                $SUDO zypper install -y $CLI_ADD
            else
                echo "No known package manager installed"
                exit 1
            fi
        fi
    fi

    # Docker installer
    printf "Do you want to install docker? <Y/n> "
    read ANSWER
    ANSWER=${ANSWER:-Y}
    case "$ANSWER" in
      [Yy])
        curl -fsSL https://get.docker.com | $SUDO sh
        $SUDO groupadd docker 2>/dev/null
        $SUDO usermod -aG docker "$USER"
        newgrp docker
        ;;
      *) echo "Skipping Docker." ;;
    esac
fi

# Python & Pyenv
if [ "$SUDO_PERM_AVAIL" = "TRUE" ]; then
    printf "Do you want to install Python? <Y/n> "
    read ANSWER
    ANSWER=${ANSWER:-Y}
    case "$ANSWER" in
      [Yy])
        $SUDO apt install -y python3
        python3 -m pip install --upgrade pip
        python3 --version

        printf "Do you want to install Pyenv? <Y/n> "
        read ANSWER
        ANSWER=${ANSWER:-Y}
        case "$ANSWER" in
          [Yy])
            curl -fsSL https://pyenv.run | sh
            python3 -m pip install --user virtualenv
            python3 -m pip install virtualenv
            cat ./pyenv.zshrc >> "${HOME}/.zshrc"
            ;;
        esac
        ;;
    esac
fi

# Conda (independent of sudo)
printf "Do you want to install Conda? <Y/n> "
read ANSWER
ANSWER=${ANSWER:-Y}
case "$ANSWER" in
  [Yy])
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
    sh Miniforge3-Linux-x86_64.sh -b -u
    rm Miniforge3-Linux-x86_64.sh
    cat ./conda.zshrc >> "${HOME}/.zshrc"
    conda config --set auto_activate_base false
    ;;
esac

# Append prompt config
cat ./prompt.zshrc >> "${HOME}/.zshrc"

# GUI apps if display available
if [ "$SUDO_PERM_AVAIL" = "TRUE" ] && [ -n "$DISPLAY" ]; then
    printf "\nWould you like to install GUI applications? <Y/n>\n(%s) " "$GUI_INSTALL"
    read ANSWER
    ANSWER=${ANSWER:-Y}
    case "$ANSWER" in
      [Yy])
        if command -v apt >/dev/null 2>&1; then
            # add repos
            $SUDO apt install -y apt-transport-https
            printf "code code/add-microsoft-repo boolean true\n" | $SUDO debconf-set-selections
            curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg \
              | $SUDO gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
            printf "deb https://repository.spotify.com stable non-free\n" \
              | $SUDO tee /etc/apt/sources.list.d/spotify.list >/dev/null
            $SUDO add-apt-repository -y ppa:nextcloud-devs/client
            $SUDO add-apt-repository -y ppa:quentiumyt/nvtop
            $SUDO apt update
            $SUDO apt install -y $GUI_INSTALL
        else
            echo "Only APT-based GUI install is supported."
            exit 1
        fi
        ;;
      *) echo "Skipping GUI applications." ;;
    esac
else
    echo "GUI not available or no sudo—skipping GUI apps."
fi

# Hand off to zsh
exec zsh -i
