# Path to your oh-my-zsh installation.
  export ZSH=~/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="xxf"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=({{VARIABLE_ZSH_PLUGINS_EXTRA}}git colorize cp tmux extract history jump command-not-found copypath copyfile isodate zsh-navigation-tools)

source $ZSH/oh-my-zsh.sh
if command -v pipx >/dev/null 2>&1; then
  pipx ensurepath >/dev/null 2>&1
fi
eval $(thefuck --alias FUCK)

autoload znt-history-widget
zle -N znt-history-widget
bindkey "^R" znt-history-widget
zle -N znt-cd-widget
bindkey "^B" znt-cd-widget
zle -N znt-kill-widget
bindkey "^Y" znt-kill-widget

source ~/.zsh_history_search

alias lss='ls -lsa'
alias aptu='sudo apt-get update && sudo apt-get full-upgrade'
alias aptuf='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo snap refresh && flatpak update -y'
alias aptall='aptuf'
alias apti='sudo apt-get install '
alias aptr='sudo apt-get remove '
alias apta='sudo apt-get autoremove'
alias aptp='sudo apt-get purge'
alias dc='docker compose'
alias ip_public='wget http://ipinfo.io/ip -qO -'

# Nice file sizes
function filesizes {
    du -sh --time -- ${1="."}/* | sort -h
}

# Custom search / find alias for global search
findg() {
    sudo find / -name "$1"
}


# Display current virtual environment
prompt_virtualenv() {
  PROMPT_VENV=""

  # Conda
  if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    local env_name="${CONDA_DEFAULT_ENV:t}"
    PROMPT_VENV="%F{yellow}[%Bconda%b ${env_name}]%f "
    return
  fi

  # Python venv
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local env_name="${VIRTUAL_ENV:t}"
    PROMPT_VENV="%F{yellow}[%Bvenv%b ${env_name}]%f "
    return
  fi

  # Pyenv (non-system only)
  if command -v pyenv >/dev/null 2>&1; then
    local pyenv_version
    pyenv_version="$(pyenv version-name 2>/dev/null)"
    if [[ -n "$pyenv_version" && "$pyenv_version" != "system" ]]; then
      PROMPT_VENV="%F{yellow}[%Bpyenv%b ${pyenv_version}]%f "
    fi
  fi
}
precmd_functions+=(prompt_virtualenv)

# change hostname in PROMPT  so I know which shell I am in
CUSTOMSERVERNAME={{VARIABLE_CUSTOMSERVERNAME}}

