#!/bin/sh
# Jump between a Rails source file and its Minitest counterpart, in both
# directions. Zed has no built-in "go to test" action, so this stands in for
# RubyMine's cmd+shift+T and is spawned as a task bound to that key.
#
# The substitution is on the first "/app/" (or "/test/") segment, which is what
# makes it work for a Rails root that is not the worktree root -- ayme keeps
# its app under rails-api/, gnosis at the top level.
set -eu

src="${1:-}"
[ -n "$src" ] || { echo "goto-test: no file given"; exit 1; }

case "$src" in
  */test/*_test.rb) dst=$(printf '%s' "$src" | sed 's|/test/|/app/|; s|_test\.rb$|.rb|') ;;
  */spec/*_spec.rb) dst=$(printf '%s' "$src" | sed 's|/spec/|/app/|; s|_spec\.rb$|.rb|') ;;
  */app/*.rb)       dst=$(printf '%s' "$src" | sed 's|/app/|/test/|; s|\.rb$|_test.rb|') ;;
  */lib/*.rb)       dst=$(printf '%s' "$src" | sed 's|/lib/|/test/lib/|; s|\.rb$|_test.rb|') ;;
  *) osascript -e "display notification \"Not a file under app/, lib/, test/ or spec/\" with title \"Go to test\"" >/dev/null 2>&1 || true
     exit 1 ;;
esac

if [ -f "$dst" ]; then
  exec zed "$dst"
fi

# The task runs with reveal "never", so a message printed here would never be
# seen. Failures go to Notification Center instead.
notify() {
  osascript -e "display notification \"$1\" with title \"Go to test\"" >/dev/null 2>&1 || true
}
notify "No counterpart yet: ${dst##*/}"
exit 1
