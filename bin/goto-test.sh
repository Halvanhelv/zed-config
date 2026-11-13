#!/bin/sh
# Jump between a Rails source file and its test, in both directions. Zed has no
# built-in "go to test" action, so this stands in for RubyMine's cmd+shift+T
# and is spawned as a task bound to that key.
#
# The substitution is on the first "/app/" (or "/test/", "/spec/") segment, so
# it works for a Rails root that is not the worktree root, e.g. an app kept
# under a subfolder of the repository.
set -eu
. "$(dirname "$0")/_common.sh"

src="${1:-}"
[ -n "$src" ] || { echo "goto-test: no file given"; exit 1; }

case "$src" in
  */test/*_test.rb) candidates=$(printf '%s' "$src" | sed 's|/test/|/app/|; s|_test\.rb$|.rb|') ;;
  */spec/*_spec.rb) candidates=$(printf '%s' "$src" | sed 's|/spec/|/app/|; s|_spec\.rb$|.rb|') ;;
  */app/*.rb)
    candidates="$(printf '%s' "$src" | sed 's|/app/|/test/|; s|\.rb$|_test.rb|')
$(printf '%s' "$src" | sed 's|/app/|/spec/|; s|\.rb$|_spec.rb|')" ;;
  */lib/*.rb)
    candidates="$(printf '%s' "$src" | sed 's|/lib/|/test/lib/|; s|\.rb$|_test.rb|')
$(printf '%s' "$src" | sed 's|/lib/|/spec/lib/|; s|\.rb$|_spec.rb|')" ;;
  *) notify "Go to test" "Not a file under app/, lib/, test/ or spec/"
     exit 1 ;;
esac

# The task runs with reveal "never", so a message printed here would never be
# seen. Failures go to a desktop notification instead.
cli=$(zed_cli) || { notify "Go to test" "Zed's command line tool is not installed (zed: install cli)"; exit 1; }

first=""
newline='
'
IFS=$newline
for dst in $candidates; do
  [ -n "$first" ] || first=$dst
  if [ -f "$dst" ]; then exec "$cli" "$dst"; fi
done

notify "Go to test" "No counterpart yet: ${first##*/}"
exit 1
