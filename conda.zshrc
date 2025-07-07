# ──────────────────────────────────────────────────────────────────────────────
# 1️⃣ load upstream conda.sh (defines __conda_activate, __conda_exe, conda(), etc.)
# ──────────────────────────────────────────────────────────────────────────────
source "${HOME}/conda/etc/profile.d/conda.sh"

# ──────────────────────────────────────────────────────────────────────────────
# 2️⃣ override conda() to add logging + rc-reload on activate/deactivate
# ──────────────────────────────────────────────────────────────────────────────
conda() {
  cmd=$1; shift
  case "$cmd" in
    activate|deactivate)
      # call the original activation routine…
      __conda_activate "$cmd" "$@" \
        && { source ~/.zshrc; }
      ;;
    *)
      # everything else delegates to the original low-level conda
      __conda_exe "$cmd" "$@"
      ;;
  esac
}