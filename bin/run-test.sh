#!/bin/sh
# Runs the test under the gutter arrow, like RubyMine's green run icon. The
# Ruby extension marks tests with the `ruby-test` tag; tasks.json binds it here.
#
#   run-test.sh FILE ROW NAME
#
# NAME is what the extension captured: the string of `test "..."`, a `test_`
# method, an RSpec description, or the class name on a class line.
#
# Minitest runs by name, not by line: with minitest 6, Rails' `file:line`
# filter is ignored and the whole file runs. The project root is the nearest
# directory with a Gemfile, so an app under a subfolder of the worktree works.
set -eu

file="$1"
row="${2:-}"
name="${3:-}"

root=$(dirname "$file")
while [ "$root" != "/" ] && [ ! -f "$root/Gemfile" ]; do root=$(dirname "$root"); done
[ -f "$root/Gemfile" ] || { echo "run-test: no Gemfile above $file"; exit 1; }
cd "$root"
rel=${file#"$root"/}

case "$rel" in
  *_spec.rb)
    if [ -x bin/rspec ]; then exec bin/rspec "$rel:$row"; fi
    exec bundle exec rspec "$rel:$row" ;;
esac

line=$(sed -n "${row}p" "$file")
if printf '%s' "$line" | grep -Eq '^[[:space:]]*def[[:space:]]+test_'; then
  set -- -n "$name"
elif printf '%s' "$line" | grep -Eq '^[[:space:]]*test[[:space:](]'; then
  set -- -n "test_$(printf '%s' "$name" | sed -E 's/[[:space:]]+/_/g')"
else
  set -- # a class line: the whole file
fi

if [ -x bin/rails ]; then exec bin/rails test "$rel" "$@"; fi
exec bundle exec ruby -Itest "$rel" "$@"
