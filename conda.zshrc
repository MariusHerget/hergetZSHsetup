# ──────────────────────────────────────────────────────────────────────────────
# 1️⃣ load upstream conda.sh (defines __conda_activate, __conda_exe, conda(), etc.)
# ──────────────────────────────────────────────────────────────────────────────

# Old style
# source "${HOME}/conda/etc/profile.d/conda.sh"

# New Style from "conda init zsh"
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/herget/conda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/herget/conda/etc/profile.d/conda.sh" ]; then
        . "/home/herget/conda/etc/profile.d/conda.sh"
    else
        export PATH="/home/herget/conda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
