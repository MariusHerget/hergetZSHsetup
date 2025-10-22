#!/bin/sh

###########################
## Default Install Stuff ##
###########################
# GUI and additional package lists
GUI_INSTALL="code spotify-client nextcloud-desktop nvtop ntfs-3g fonts-firacode ttf-mscorefonts-installer firefox chromium-browser"
CLI_ADD="build-essential make cmake git 7zip zip gcc g++ e2fsprogs speedtest"

###########
## SETUP ##
###########
# Internal Commands
. ./internal_commands.sh

# Variables
RUN_AFTER_DONE="echo '$INT_SETUP_PREFIX  Running additional setup stuff'"

# Ask for machine name
s_question "What should this machine be named?" MACHINE_NAME

# Determine if we have sudo
SUDO=""
SUDO_PERM_AVAIL="FALSE"
if [ "$(id -u)" -ne 0 ]; then
    s_question_yn "Do you have sudo permissions on this machine?" HAS_SUDO N
    case "$HAS_SUDO" in
      [Yy]) SUDO="sudo"; SUDO_PERM_AVAIL="TRUE" ;;
      *) s_echo "No installations can be performed." 1 ;;
    esac
else
    SUDO_PERM_AVAIL="TRUE"
fi

#############
## INSTALL ##
#############
# If sudo/root available, prepare core install list
if [ "$SUDO_PERM_AVAIL" = "TRUE" ]; then
    # Required tools
    INSTALL_PKGS="zsh curl util-linux-user trash-cli apt-transport-https ca-certificates wget software-properties-common vim htop btop tmux"
    s_echo "Installing required and recommended packages"
    s_echo "($INSTALL_PKGS)" 1

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
            s_error "No known package manager installed"
        fi
    fi
fi

# Ensure default shell is zsh
if ! echo "$SHELL" | grep -q 'zsh'; then
    $SUDO chsh "$(whoami)" -s "$(command -v zsh)"
fi
s_echo "\$SHELL -> zsh"

# Backing up some files:
FILES_TO_BACKUP_REQUIRED="
${HOME}/.zshrc
${HOME}/.tmux.conf
"
s_backup_multiple_files $FILES_TO_BACKUP_REQUIRED 

#############
## OhMyZSH ##
#############
# Install OhMyZsh
 s_echo "Installing OhMyZsh and XXF theme"
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
    # cp "${HOME}/.zshrc" "${HOME}/.zshrc.orig" 2>/dev/null
else
    s_echo "OhMyZsh already present." 1
fi

# Copy custom theme if missing
if [ ! -f "${HOME}/.oh-my-zsh/themes/xxf.zsh-theme" ]; then
    cp ./xxf.zsh-theme "${HOME}/.oh-my-zsh/themes/xxf.zsh-theme"
else
    s_echo "XXF theme already installed." 1
fi

###############
## ZSH SETUP ##
###############
# Install user config files
s_echo "Configuring personalized ZSH."
s_echo "Copying .zshrc and .tmux.conf" 1
cp .zshrc "${HOME}/.zshrc"
cp .tmux.conf "${HOME}/.tmux.conf"

# substitute machine name placeholder
sed -i "s|{{VARIABLE_CUSTOMSERVERNAME}}|$MACHINE_NAME|g" "${HOME}/.zshrc"

# Source additional config if present
s_echo "Checking for .aliases" 1
if [ -f "./.aliases" ]; then
  s_rc_ensure_line "${HOME}/.zshrc" "source $PWD/.aliases"
  s_echo "Added '$PWD/.aliases'" 2
fi

s_echo "Checking for .user-conf" 1
if [ -f "./.user-conf" ]; then
  s_rc_insert_before "${HOME}/.zshrc" 'source[[:space:]]+\$ZSH/oh-my-zsh\.sh' "source $PWD/.user-conf"
  s_echo "'$PWD/.user-conf' inserted before 'source \$ZSH/oh-my-zsh.sh'." 2
fi

# Source any other alias files in home
s_echo "Checking for .aliases in \$HOME" 1
for f in $(ls -A "${HOME}" | grep '\.aliases'); do
  [ -f "$f" ] || continue
  s_rc_ensure_line "${HOME}/.zshrc" "source $f"
  s_echo "Added '$(basename "$f")/" 2
done

# If root/sudo, append system PATH to zprofile
if [ "$SUDO_PERM_AVAIL" = "TRUE" ]; then
    s_echo "Inserting PATH into /etc/zsh/zprofile" 1
    printf 'PATH=%s\nexport PATH\n' "$PATH" | $SUDO tee -a /etc/zsh/zprofile >/dev/null
fi

# Ask about trash alias
s_question_yn "Do you want to use trash for rm?" ANSWER_USE_TRASH Y 1
case "$ANSWER_USE_TRASH" in
  [Yy])
    s_rc_ensure_line "${HOME}/.zshrc" "alias rm='trash'"
    ;;
esac

# Additional CLI tools
if [ "$SUDO_PERM_AVAIL" = "TRUE" ] && [ -n "$CLI_ADD" ]; then
    s_question_yn "Do you want to install additional CLI tools?" ANSWER_CLI_ADD Y 0 $CLI_ADD
    case "$ANSWER_CLI_ADD" in
      [Yy])
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
            s_error "No known package manager installed"
        fi
      *) s_echo "Skipping additional CLI tools." 2 ;;
    esac

    # Docker installer
    s_question_yn "Do you want to install docker?" ANSWER_DOCKER N
    case "$ANSWER_DOCKER" in
      [Yy])
        s_echo "Downloading docker installer..." 1
        curl -L --progress-bar -o docker.sh "https://get.docker.com"
        indent_custom "$INT_SETUP_PREFIX_DOCKER" 2 sh docker.sh
        rm docker.sh
        indent_custom "$INT_SETUP_PREFIX_DOCKER" 2 $SUDO groupadd docker 2>/dev/null
        indent_custom "$INT_SETUP_PREFIX_DOCKER" 2 $SUDO usermod -aG docker "$USER"
        indent_custom "$INT_SETUP_PREFIX_DOCKER" 2 newgrp docker
        ;;
      *) s_echo "Skipping Docker." 2 ;;
    esac
fi

# Python & Pyenv
if [ "$SUDO_PERM_AVAIL" = "TRUE" ]; then
    s_question_yn "Do you want to install Python?" ANSWER_PYTHON Y
    case "$ANSWER_PYTHON" in
      [Yy])
        $SUDO apt install -y python3
        python3 -m pip install --upgrade pip
        python3 --version

        s_question_yn "Do you want to install Pyenv?" ANSWER_PYTHON_PYENV Y 1
        case "$ANSWER_PYTHON_PYENV" in
          [Yy])
            s_echo "Downloading pyenv installer..." 2
            curl -L --progress-bar -o pyenv.sh "https://pyenv.run"
            indent_custom "$INT_SETUP_PREFIX_PYENV" 3 bash pyenv.sh
            rm pyenv.sh
            indent_custom "$INT_SETUP_PREFIX_PYENV" 3 python3 -m pip install --user virtualenv
            indent_custom "$INT_SETUP_PREFIX_PYENV" 3 python3 -m pip install virtualenv
            cat ./pyenv.zshrc >> "${HOME}/.zshrc"
            ;;
        esac
        ;;
    esac
fi


# Conda (independent of sudo)
s_question_yn "Do you want to install Conda (Miniforge3)?" ANSWER_CONDA Y
case "$ANSWER_CONDA" in
  [Yy])
    s_question "Conda installation directory:" ANSWER_CONDA_DIR "${HOME}/conda" 1
    mkdir -p "$ANSWER_CONDA_DIR"
    s_echo "Downloading Miniforge installer (Miniforge3-$(uname)-$(uname -m).sh)..." 1
    curl -L --progress-bar -o Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    indent_custom "$INT_SETUP_PREFIX_CONDA" 2 bash Miniforge3.sh -b -u -p "$ANSWER_CONDA_DIR"
    . "${HOME}/conda/etc/profile.d/conda.sh"
    rm Miniforge3.sh

    # Installation and cleanup done.
    RUN_AFTER_DONE="$RUN_AFTER_DONE && conda init zsh 2>&1 | sed 's/^/\t$INT_SETUP_PREFIX_CONDA /'"
    RUN_AFTER_DONE="$RUN_AFTER_DONE && conda config --set auto_activate_base false"
    RUN_AFTER_DONE="$RUN_AFTER_DONE && conda config --set changeps1 false"
    
    # Mamba Support
    s_question_yn "Would you like to add Mamba support?" ANSWER_MAMBA N 1
    case "$ANSWER_MAMBA" in
        [Yy])
        s_echo "Mamba support will be activated." 2
        RUN_AFTER_DONE="$RUN_AFTER_DONE && mamba shell init"
        ;;
        [Nn])
        s_echo "Mamba support not activated. Run 'mamba shell init' to activate later." 2
        ;;
    esac
    ;;
esac

# Append prompt config
cat ./prompt.zshrc >> "${HOME}/.zshrc"

# GUI apps if display available
if [ "$SUDO_PERM_AVAIL" = "TRUE" ] && [ -n "$DISPLAY" ]; then
    s_question_yn "Would you like to install GUI applications?" ANSWER_GUI_INSTALL N 0 $GUI_INSTALL
    case "$ANSWER_GUI_INSTALL" in
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
            s_error "Only APT-based GUI install is supported."
        fi
        ;;
      *) s_echo "Skipping GUI applications." 1 ;;
    esac
else
    s_echo "GUI not available or no sudo. Skipping GUI apps." 0
fi

# Hand off to zsh
# printf '%s\n' "$RUN_AFTER_DONE"
exec zsh -i -c "$RUN_AFTER_DONE"
