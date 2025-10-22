
precmd_update_prompt() {
PROMPT="
%{$fg[cyan]%}%n \
%{$fg[white]%}at \
%{$fg[green]%}$(box_name) ($CUSTOMSERVERNAME) \
%{$fg[white]%}in \
%{$terminfo[bold]$fg[yellow]%}[${current_dir}]%{$reset_color%} \
${hg_info} \
${git_info} \
${git_last_commit}
%{$fg[red]%}%* $(prompt_virtualenv)\
%{$terminfo[bold]$fg[white]%}› %{$reset_color%}"

if [[ "$USER" == "root" ]]; then
# PROMPT="
# %{$fg[red]%}%* \
# %{$terminfo[bold]$fg[blue]%}#%{$reset_color%} \
# %{$bg[yellow]%}%{$fg[cyan]%}%n%{$reset_color%} \
# %{$fg[white]%}at \
# %{$fg[green]%}$(box_name) ($CUSTOMSERVERNAME) \
# %{$fg[white]%}in \
# %{$terminfo[bold]$fg[yellow]%}[${current_dir}]%{$reset_color%}\
# ${hg_info}\
# ${git_info}
# %{$terminfo[bold]$fg[red]%}$ %{$reset_color%}"
PROMPT="
%{$fg[cyan]%}%n \
%{$fg[white]%}at \
%{$fg[green]%}$(box_name) ($CUSTOMSERVERNAME) \
%{$fg[white]%}in \
%{$terminfo[bold]$fg[yellow]%}[${current_dir}]%{$reset_color%} \
${hg_info} \
${git_info} \
${git_last_commit}
%{$fg[red]%}%* $(prompt_virtualenv)\
%{$terminfo[bold]$fg[white]%}› %{$reset_color%}"

fi
}
precmd_functions+=( precmd_update_prompt )

