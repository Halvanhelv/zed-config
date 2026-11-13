# Sourced by the scripts in bin/: what differs between macOS and Linux.

# Where Zed keeps installed extensions.
zed_data_dir() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' "$HOME/Library/Application Support/Zed" ;;
    *) printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/zed" ;;
  esac
}

ruby_highlights_scm() {
  printf '%s\n' "$(zed_data_dir)/extensions/installed/ruby/languages/ruby/highlights.scm"
}

# A desktop notification, for scripts whose terminal nobody sees.
notify() {
  title="$1"
  message="$2"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message" >/dev/null 2>&1 || true
  fi
}

# Zed's command line tool: `zed` on macOS (zed: install cli), `zeditor` or
# `zedit` in some Linux packages.
zed_cli() {
  for cli in zed zeditor zedit; do
    if command -v "$cli" >/dev/null 2>&1; then
      printf '%s\n' "$cli"
      return 0
    fi
  done
  return 1
}
