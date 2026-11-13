#!/bin/sh
# Prepare a freshly cloned copy of this configuration for use.
#
# Cloning is the install: this repository *is* ~/.config/zed, so there are no
# files to copy. What needs doing is the part a clone cannot carry -- an
# absolute path baked into tasks.json, the executable bit, and the language
# server that has to exist under the right Ruby.
set -eu

here=$(cd "$(dirname "$0")" && pwd)

if [ "$here" != "$HOME/.config/zed" ]; then
  echo "warning: expected to be at ~/.config/zed, found $here"
  echo "         Zed reads only that path; move the clone there first."
fi

chmod +x "$here"/bin/*

# tasks.json and settings.json name the helpers by absolute path -- Zed does
# not expand ~ there.
for f in tasks.json settings.json; do
  if grep -q '"/Users/[^"]*/.config/zed/bin/' "$here/$f" 2>/dev/null; then
    tmp=$(mktemp)
    sed "s|\"/Users/[^\"]*/\.config/zed/bin/|\"$here/bin/|" "$here/$f" > "$tmp"
    cat "$tmp" > "$here/$f" && rm "$tmp"
    echo "$f: helper paths rewritten to $here/bin/"
  fi
done

# Zed installs ruby-lsp for nobody. It is resolved from PATH, so it must exist
# under the Ruby each project pins -- a version that lacks it fails silently
# with "rbenv: ruby-lsp: command not found" and the editor simply has no Ruby
# intelligence at all. Install it per Ruby version, not once.
# Every rbenv Ruby it supports (3.0 and up), not only the current one.
if command -v rbenv >/dev/null 2>&1; then
  for v in $(rbenv versions --bare); do
    case "$v" in 1.* | 2.*) continue ;; esac
    if RBENV_VERSION=$v gem list -i ruby-lsp >/dev/null 2>&1; then
      echo "ruby-lsp: present for ruby $v"
    else
      echo "ruby-lsp: missing for ruby $v -- installing"
      RBENV_VERSION=$v gem install ruby-lsp --no-document
    fi
  done
  rbenv rehash
elif command -v ruby >/dev/null 2>&1 && ! command -v ruby-lsp >/dev/null 2>&1; then
  gem install ruby-lsp
fi

# settings.json asks for JetBrains Mono. JetBrains IDEs ship their own copy
# inside the bundled runtime and never install it system-wide, so the font can
# look present in RubyMine while Zed silently falls back to something else --
# which reads as the text being oddly grainy rather than as a missing font.
if ! ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi jetbrainsmono; then
  jb=$(ls -d /Applications/*.app/Contents/jbr/Contents/Home/lib/fonts 2>/dev/null | head -1)
  if [ -n "${jb:-}" ] && ls "$jb"/JetBrainsMono-*.ttf >/dev/null 2>&1; then
    mkdir -p "$HOME/Library/Fonts"
    cp "$jb"/JetBrainsMono-*.ttf "$HOME/Library/Fonts/"
    echo "JetBrains Mono: installed from $jb"
  else
    echo "JetBrains Mono: not installed and no JetBrains IDE to copy it from."
    echo "  Get it at https://www.jetbrains.com/lp/mono/ or change"
    echo "  buffer_font_family in settings.json."
  fi
else
  echo "JetBrains Mono: already installed"
fi

# The Ruby grammar cannot tell the Rails DSL from any other method call, so the
# highlighting patch lives outside the theme. Applying it needs the Ruby
# extension on disk, which only happens after Zed has run once.
if [ -f "$HOME/Library/Application Support/Zed/extensions/installed/ruby/languages/ruby/highlights.scm" ]; then
  "$here/bin/patch-ruby-highlights.sh" || true
else
  echo "ruby extension not installed yet -- run bin/patch-ruby-highlights.sh"
  echo "  after Zed's first launch (and again after it updates the extension)."
fi

# Extension updates replace the Ruby grammar and drop the patch. A launchd agent
# watches for that and re-applies it.
agent=zed-config.patch-ruby-highlights
plist="$HOME/Library/LaunchAgents/$agent.plist"
mkdir -p "$HOME/Library/LaunchAgents"
sed "s|__HOME__|$HOME|g" "$here/launchd/$agent.plist" > "$plist"
launchctl bootout "gui/$(id -u)/$agent" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "launchd: $agent loaded"

echo
echo "Done. Zed installs the rest on first launch:"
echo "  - extensions listed under auto_install_extensions (ruby, vue, html, emmet)"
echo "  - herb, tailwindcss, vtsls and vue language servers, on demand"
echo "  - the Claude agent, via npx, on its first thread (then run /login)"
