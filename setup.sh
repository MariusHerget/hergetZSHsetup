#!/bin/sh
read -p "What should this machine be named? " prompt
MACHINENAME=$prompt

GUIINSTALL=" code spotify-client nextcloud-desktop nvtop ntfs-3g fonts-firacode ttf-mscorefonts-installer firefox chromium-browser"
INSTALLADD=" build-essential make cmake git 7zip zip gcc g++ e2fsprogs speedtest btop"
INSTALL=""
# Check for root
SUDO=''
if [ `whoami` != root ]; then
    SUDO='sudo'
fi
# Install zsh and change standard shell
if [ $(which zsh) ]; then
    echo "ZSH already installed"
else
    INSTALL=$INSTALL" zsh"
fi

if [ $(which curl) ]; then
    echo "CURL already installed"
else
    INSTALL=$INSTALL" curl"
fi

# Check if chsh is installed
if [ $(which chsh) ]; then
    echo "chsh already installed"
else
    INSTALL=$INSTALL" util-linux-user"
fi

INSTALL=$INSTALL" trash-cli apt-transport-https ca-certificates wget software-properties-common vim htop tmux"

if [ ! -z $INSTALL ]; then
    if [ $(which apt) ]; then
        $SUDO apt install $INSTALL
    elif [ $(which brew) ]; then
        $SUDO install $INSTALL
    elif [ $(which yum) ]; then
        $SUDO yum install $INSTALL
    elif [ $(which zypper) ]; then
        $SUDO zypper install $INSTALL
    else
        echo "No known package manager installed"
        exit
    fi
fi

if ! $(echo $SHELL | grep -q "zsh"); then
    $SUDO chsh $(whoami) -s $(which zsh)
fi
echo "\$SHELL -> zsh"

# Install Oh My Zsh
if ! [ -d ~/.oh-my-zsh ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    cp ~/.zshrc ~/.zshrc.orig 2> /dev/null
fi

# Copy xxf theme
if ! [ -f ~/.oh-my-zsh/themes/xxf.zsh-theme ]; then
    cp ./xxf.zsh-theme ~/.oh-my-zsh/themes/xxf.zsh-theme
fi

# Copy .zshrc
cp .zshrc ~/.zshrc
sed "s/{{VARIABLE_CUSTOMSERVERNAME}}/$MACHINENAME/g" 

# Insert conf files into zshrc
if [ -e $PWD/.aliases ]; then
	echo "source $PWD/.aliases" >> ~/.zshrc
    echo "Added .aliases as source in zshrc"
fi

#if [ -e $PWD/.user-conf ]; then
#    prompt=y
#else
#    read -p "Do you want to create a User Config file? <y/N> " prompt
#fi
#if (echo "$prompt" | grep -Eq "^[yY](es)*$"); then
#    touch $PWD/.user-conf
#    echo "export DOTCONFPATH=$PWD" >> ~/.zshrc
#    echo "Created .user-conf"
#fi

if [ -e $PWD/.user-conf ]; then
    tmp=$(mktemp)
    awk -v pwd=$PWD '!found && /source \$ZSH\/oh-my-zsh.sh/ { print "source "pwd"/.user-conf"; found=1 } 1' ~/.zshrc > $tmp
    mv $tmp ~/.zshrc
    echo "Added .user-conf as source in zshrc"
fi

# Insert already exisiting conf files into zsh
for f in $(ls -a ~ | grep \.\*aliases\.\*); do
	echo "source ~/$f" >> ~/.zshrc
    echo "Added $f as source in zshrc"
done

# insert Profile path in zprofile
echo "PATH=$(echo $PATH)" | $SUDO tee -a /etc/zsh/zprofile
echo "export PATH" | $SUDO tee -a /etc/zsh/zprofile

zsh

# Install addtional
echo "\n#####"
read -p "Do you want to install additional CLI tools? <Y/n> \n($INSTALLADD) " prompt
if (echo "$prompt" | grep -Eq "^[nN](o)*$"); then
    if [ ! -z $INSTALLADD ]; then
        if [ $(which apt) ]; then
            # speedtest cli
            curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
            # Update and install
            $SUDO apt update
            $SUDO apt install $INSTALLADD
        elif [ $(which brew) ]; then
            $SUDO install $INSTALLADD
        elif [ $(which yum) ]; then
            # speedtest cli
            curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
            # Update and install
            $SUDO yum install $INSTALLADD
        elif [ $(which zypper) ]; then
            $SUDO zypper install $INSTALLADD
        else
            echo "No known package manager installed"
            exit
        fi
    fi
fi

# Docker install
read -p "Do you want to install docker? <Y/n> " prompt
if (echo "$prompt" | grep -Eq "^[nN](o)*$"); then
    curl -fsSL https://get.docker.com | $SUDO bash
    $SUDO groupadd docker
    $SUDO usermod -aG docker $USER
    newgrp docker
fi

# Python install
PYTHONVERS=python3
read -p "Do you want to install Python? <Y/n> " prompt
if (echo "$prompt" | grep -Eq "^[nN](o)*$"); then
    $SUDO apt install $PYTHONVERS
    $PYTHONVERS -m pip install --upgrade pip
    $PYTHONVERS --version
    read -p "Do you want to install Pyenv? <Y/n> " prompt
    if (echo "$prompt" | grep -Eq "^[nN](o)*$"); then
        curl -fsSL https://pyenv.run | bash
        $PYTHONVERS -m pip install --user virtualenv    
        $PYTHONVERS -m pip install virtualenv        
        cat ./pyenv.zshrc >> ~/.zshrc
    fi
    read -p "Do you want to install Conda? <Y/n> " prompt
    if (echo "$prompt" | grep -Eq "^[nN](o)*$"); then
        wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh 
        sh ./Miniforge3-Linux-x86_64.sh -b -u
        $SUDO sh ./Miniforge3-Linux-x86_64.sh -b -u
        rm ./Miniforge3-Linux-x86_64.sh
        cat ./conda.zshrc >> ~/.zshrc
    fi
fi

cat ./prompt.zshrc >> ~/.zshrc

zsh

# GUI INSTALL
if [ x$DISPLAY != x ] ; then
  echo "\n#####"
  echo "GUI Enabled"
  read -p "Would you like to install gui applications? <Y/n> \n($GUIINSTALL) " prompt
  if (echo "$prompt" | grep -Eq "^[nN](o)*$"); then
    echo "Okay we will NOT install gui applications!"
  else
    echo "Install gui applications!"
    if [ ! -z $GUIINSTALL ]; then
        if [ $(which apt) ]; then
            $SUDO apt install apt-transport-https
            # VS Code
            echo "code code/add-microsoft-repo boolean true" | $SUDO debconf-set-selections
            # Spotify 
            curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | $SUDO gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
            echo "deb https://repository.spotify.com stable non-free" | $SUDO tee /etc/apt/sources.list.d/spotify.list
            # nextcloud
            $SUDO add-apt-repository ppa:nextcloud-devs/client
            # nvtop
            sudo add-apt-repository ppa:quentiumyt/nvtop
            # Update and install
            $SUDO apt update
            $SUDO apt install $GUIINSTALL
        else
            echo "Only works with APT for now."
            exit
        fi
    fi
  fi
else
  echo "GUI Disabled - GUI applications will not be installed"
fi
