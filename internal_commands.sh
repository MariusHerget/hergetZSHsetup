#!/bin/sh
INT_SETUP_PREFIX="  [SETUP]"
INT_SETUP_PREFIX_ERROR="  [ERROR]"
INT_SETUP_PREFIX_CONDA="  [CONDA]"
INT_SETUP_PREFIX_DOCKER="  [DOCKER]"
INT_SETUP_PREFIX_PYENV="  [PYENV]"

# build prefix of N tabs
_tabs(){ _t_n=${1:-1}; _t_pad=''; _t_i=0; while [ "$_t_i" -lt "$_t_n" ]; do _t_pad="${_t_pad}\t"; _t_i=$((_t_i+1)); done; printf '%b' "$_t_pad"; }

# some helper commands
echo_tab() { n=${1:-1}; shift; printf '%s%s\n' "$(_tabs "$n")" "$*"; }
indent()   { n=${1:-1}; shift; "$@" 2>&1 | sed "s/^/$(_tabs "$n")/"; }
indent_custom() { 
  PREFIX_indent_custom=$1; n=${2:-0}; shift 2; 
  "$@" 2>&1 | sed "s/^/$PREFIX_indent_custom $(_tabs "$n") /"; 
  echo "$PREFIX_indent_custom Done."; 
}
s_printf() {
    fmt=$1; tabs_s_printf=${2:-0}; 
    [ $# -gt 1 ] && shift 2 || shift 1; 
    printf "$INT_SETUP_PREFIX %b$fmt" "$(_tabs "$tabs_s_printf")" "$@";
}
s_echo() {
    fmt=$1; tabs_s_echo=${2:-0}; 
    [ $# -gt 1 ] && shift 2 || shift 1; 
    printf "$INT_SETUP_PREFIX %b$fmt\n" "$(_tabs "$tabs_s_echo")" "$@";
}
s_error() {
    fmt=$1; tabs_s_error=${2:-0}; 
    [ $# -gt 1 ] && shift 2 || shift 1; 
    printf "$INT_SETUP_PREFIX_ERROR %b$fmt\n" "$(_tabs "$tabs_s_error")" "$@";
    printf "$INT_SETUP_PREFIX_ERROR %bExiting.\n" "$(_tabs "$tabs_s_error")" "$@";
    exit 1;
}

# ask a question with optional default value
s_question() {
  prompt=$1 varname=$2 default=$3 tabs_s_question=${4:-0}
  if [ -n "$default" ]; then
    s_printf "$prompt [$default] " $tabs_s_question
  else
    s_printf "$prompt " $tabs_s_question
  fi
  read "$varname"
  eval "[ -n \"\${$varname}\" ] || $varname=\"\$default\""
}

# ask yes/no question with default (Y or N) and enforce valid input
s_question_yn() {
  prompt=$1 varname=$2 default=${3:-N} tabs_s_question_yn=${4:-0} details=${5:-}
  tabs_s_question_yn_loop=$tabs_s_question_yn
  tabs_s_question_yn_loop=$((tabs_s_question_yn_loop + 1))

  case "$default" in
    [Yy]) opts="<Y/n>" ;;
    [Nn]) opts="<y/N>" ;;
    *)    opts="<y/n>" ;;
  esac

  while :; do
    if [ -n "$details" ]; then
      s_printf "$prompt $opts\n" $tabs_s_question_yn
      s_printf "($details) " $tabs_s_question_yn_loop
    else
      s_printf "$prompt $opts " $tabs_s_question_yn
    fi
    read input
    input=${input:-$default}
    input=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')

    case "$input" in
      y|yes) eval "$varname=Y"; break ;;
      n|no)  eval "$varname=N"; break ;;
      *)     s_printf "Please answer y/n or yes/no.\n" $tabs_s_question_yn_loop ;;
    esac
  done
}

# ---- internal backup (no output) ----
s_int_backup_file() {
  file=$1
  [ ! -e "$file" ] && return 0  # skip if file doesn't exist

  timestamp=$(date +%Y_%m_%d-%H_%M_%S)

  if [ -e "$file.orig" ]; then
    NEW_FILE="$file.orig-$timestamp"
  else
    NEW_FILE="$file.orig"
  fi

  cp -- "$file" "$NEW_FILE"
  printf '%s' "$NEW_FILE"  # print new filename for caller
}

# ---- external backup (with echo) ----
s_backup_file() {
  file=$1 tabs_s_backup_file=${2:-0}
  NEW_FILE=$(s_int_backup_file "$file")
  [ -z "$NEW_FILE" ] && return 0  # no backup made

  s_echo "Backed up: $file --> $NEW_FILE." $tabs_s_backup_file
}

# ---- backup multiple files ----
s_backup_multiple_files() {
  # all but last argument are files, last one may be optional tabs
  last_arg=${!#}
  case "$last_arg" in
    ''|*[!0-9]*) tabs_s_backup_multiple=0; files="$@";;  # last arg not numeric
    *) tabs_s_backup_multiple=$last_arg; set -- "${@:1:$(($#-1))}"; files="$@";;
  esac

  for f in $files; do
    s_backup_file "$f" "$tabs_s_backup_multiple"
  done
}

s_backup_multiple_files() {
  # optional last arg = tab count
  last=${!#}
  case "$last" in ''|*[!0-9]*) tabs_s_backup_multiple_files=0 ;; *) tabs_s_backup_multiple_files=$last; set -- "${@:1:$(($#-1))}" ;; esac
  tabs_s_backup_multiple_files_next=$((tabs_s_backup_multiple_files + 1))

  any=0
  for f in "$@"; do
    NEW_FILE="$(s_int_backup_file "$f")" || NEW_FILE=""
    [ -n "$NEW_FILE" ] || continue
    [ $any -eq 0 ] && { s_echo "Backing up:" "$tabs_s_backup_multiple_files"; any=1; }
    s_echo "- $f --> $NEW_FILE" "$tabs_s_backup_multiple_files_next"
  done
}


# ensure a line exists once in rc; append if missing
s_rc_ensure_line() { rc=$1; line=$2; grep -qxF -- "$line" "$rc" 2>/dev/null || printf "%s\n" "$line" >> "$rc"; }

# insert a line before first match; only if not already present
s_rc_insert_before() {
  rc=$1; pattern=$2; line=$3
  grep -qxF -- "$line" "$rc" 2>/dev/null && return 0
  tmp=$(mktemp) || return 1
  awk -v ins="$line" -v pat="$pattern" ' !done && $0 ~ pat { print ins; done=1 } { print } ' "$rc" > "$tmp" && mv "$tmp" "$rc"
}