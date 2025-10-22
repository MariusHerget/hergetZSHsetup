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
plugins=({{VARIABLE_ZSH_PLUGINS_EXTRA}}git colorize ssh cp tmux extract history thefuck jump command-not-found copypath copyfile isodate zsh-navigation-tools)

source $ZSH/oh-my-zsh.sh

autoload znt-history-widget
zle -N znt-history-widget
bindkey "^R" znt-history-widget
zle -N znt-cd-widget
bindkey "^B" znt-cd-widget
zle -N znt-kill-widget
bindkey "^Y" znt-kill-widget


alias lss='ls -lsa'
alias aptu='sudo apt-get update && sudo apt-get upgrade'
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

prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# Display current virtual environment
prompt_virtualenv() {
  local env='';
  local out_env='';
  local out_vers='';
  
  # if "$CONDA_DEFAULT_ENV" variable exists,
  # then you are using conda to manage python virtual env
  if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    env="$CONDA_DEFAULT_ENV"
    out_env="conda"
    out_vers="$(basename $env)"
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    env="$VIRTUAL_ENV"
    out_env="venv"
    out_vers="$(basename $env)"
  elif [[ -n $PYENV_SHELL ]]; then
    local version
    local pyv
    pyv=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
    version=${(@)$(pyenv version)[1]}
    if [[ $version != system ]]; then
        out_env="pyenv"
        out_vers="$version: $pyv"
    fi
  fi
  local color="yellow"
  local out='$fg[$color]%{\e[2m%}[$out_env] $out_vers%{\e[22m%}%{$reset_color%} '

  if [[ -n $env ]]; then
   color=yellow
   print -Pn $out
  fi
}
precmd_functions+=( prompt_virtualenv )

# change hostname in PROMPT  so I know which shell I am in
CUSTOMSERVERNAME={{VARIABLE_CUSTOMSERVERNAME}}
