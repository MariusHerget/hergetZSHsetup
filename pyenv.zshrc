# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
  	echo -n "(`basename $virtualenv_path`)"
  fi
}

prompt_pyenv() {
  if [[ -n $PYENV_SHELL ]]; then
    local version
    local pyv
    pyv=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
    version=${(@)$(pyenv version)[1]}
    if [[ $version != system ]]; then
    	echo -n "($version: $pyv)"
    fi
  fi
}


export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
