#!/usr/bin/env bash
#
# monitor_nodes.sh
#
#   Auto-launch a tmux session with one $COMMAND per compute node.
#
# Usage:
#   ./monitor_nodes.sh
#
# Requirements:
#   • tmux must be installed on the login node.
#   • Passwordless SSH (via keys) to compute nodes so `ssh nodeXXX -t $COMMAND` does not prompt.
#   • Your Slurm username ($USER) matches the jobs you want to monitor.
#

set -e

# Name of the tmux session and first window
SESSION="node_monitor_btop"
WINDOW="main"
COMMAND="/var/scratch/mherget/btop/bin/btop --config /var/scratch/mherget/hergetZSHsetup/.btopconfigs/das6-node-tmux.conf"

# 1) Grab the unique list of nodes where YOUR jobs are running:
#    - squeue   : list your running jobs
#    - -u $USER : only your username
#    - -h       : no header line
#    - -o "%N"  : output only the NODES column
#    - tr ',' '\n' converts comma‐separated lists into one-per-line
#    - sort -u                  deduplicates
nodes=$(squeue -u "$USER" -h -o "%N" 2>/dev/null | tr ',' '\n' | sort -u)

if [[ -z "$nodes" ]]; then
  echo "No running jobs found for user '$USER'."
  exit 1
fi

# 2) If a tmux session by this name already exists, bail:
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "A tmux session named '$SESSION' already exists."
  echo "→ Attach to it with:  tmux attach -t $SESSION"
  echo "   or kill it first:   tmux kill-session -t $SESSION"
  exit 1
fi

# 3) Create a new, detached tmux session with one window named "main"
tmux new-session -d -s "$SESSION" -n "$WINDOW"

tmux set -g pane-border-status top

tmux set -g pane-border-format " [ ###P #T ] "

# 4) Send 'ssh <node> -t $COMMAND' to the first pane of node_monitor:main
#    No need to specify a pane index—tmux will use pane 0 by default.
first_node=$(printf "%s\n" $nodes | head -n1)
tmux send-keys -t "${SESSION}:${WINDOW}" "ssh $first_node -t $COMMAND" C-m
tmux select-pane -t "${SESSION}:${WINDOW}" -T "$first_node"

# 5) For each additional node, split the main window and run ssh…$COMMAND in the new pane
#    We use `split-window -t session:window` which splits the currently active pane in that window.
#    After splitting, tmux automatically selects the new pane, so the next split will subdivide that.
is_first=true
while read -r nd; do
  if $is_first; then
    is_first=false
    continue
  fi
  tmux split-window -t "${SESSION}:${WINDOW}" "ssh $nd -t $COMMAND"
  tmux select-pane -t "${SESSION}:${WINDOW}" -T "$nd"
done <<< "$nodes"

# 6) Tile all existing panes in node_monitor:main into a grid
tmux select-layout -t "${SESSION}:${WINDOW}" tiled

# 7) Ensure session will exit automatically when no windows remain
tmux set-option -t "$SESSION" exit-empty on

# 8) Attach to the session so you immediately see all panes and move focus to the right pane
tmux attach -t "$SESSION"