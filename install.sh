#!/bin/sh
# Set up the parts of this configuration that a clone cannot carry, and undo
# them with --uninstall. Safe to run again at any time.
#
#   ~/.config/zed/install.sh              install or repair
#   ~/.config/zed/install.sh --uninstall  remove what it installed
#
# It touches only these, and prints each step:
#   - every Ruby 3.0+ it finds: the ruby-lsp gem, and a link to the ruby-lsp
#     add-on in that Ruby's site_ruby directory
#   - the JetBrains Mono font, when it is missing
#   - a link from Zed's extensions directory to extensions/jetbrains-icons-ruby
#   - the Rails DSL patch on the Ruby extension's highlights.scm
#   - on macOS, a launchd agent that re-applies that patch after updates
set -eu

here=$(cd "$(dirname "$0")" && pwd)
. "$here/bin/_common.sh"

agent=zed-config.patch-ruby-highlights
agent_plist="$HOME/Library/LaunchAgents/$agent.plist"
icons_link="$(zed_data_dir)/extensions/installed/jetbrains-icons-ruby"
addon="$here/ruby-lsp/lib/ruby_lsp/zed_locals/addon.rb"

# Every Ruby on this machine: the version managers' install directories plus
# whatever `ruby` is on PATH. Each is driven through its own binary, so no
# manager-specific environment is needed.
rubies() {
  {
    for dir in "$HOME/.rbenv/versions" "$HOME/.asdf/installs/ruby" \
               "${XDG_DATA_HOME:-$HOME/.local/share}/mise/installs/ruby" "$HOME/.rubies"; do
      [ -d "$dir" ] && ls -d "$dir"/*/bin/ruby 2>/dev/null
    done
    command -v ruby 2>/dev/null
  } | while read -r ruby; do
    [ -x "$ruby" ] || continue
    # Resolve rbenv/asdf shims to the real binary, so each Ruby appears once.
    "$ruby" -e 'print RbConfig.ruby' 2>/dev/null && echo
  done | sort -u
}

ruby_version() { "$1" -e 'print RUBY_VERSION'; }
ruby_site_addon() { printf '%s/ruby_lsp/zed_locals/addon.rb\n' "$("$1" -e 'print RbConfig::CONFIG["sitelibdir"]')"; }

if [ "${1:-}" = "--uninstall" ]; then
  if [ -f "$agent_plist" ]; then
    launchctl bootout "gui/$(id -u)/$agent" 2>/dev/null || true
    rm "$agent_plist"
    echo "launchd: $agent removed"
  fi

  scm=$(ruby_highlights_scm)
  if [ -f "$scm.orig" ]; then
    cp "$scm.orig" "$scm" && rm "$scm.orig"
    echo "Ruby extension: highlights.scm restored"
  fi

  if [ -L "$icons_link" ]; then
    rm "$icons_link"
    echo "icon theme: link removed"
  fi

  rubies | while read -r ruby; do
    link=$(ruby_site_addon "$ruby")
    if [ -L "$link" ]; then
      rm "$link" && rmdir "$(dirname "$link")" 2>/dev/null || true
      echo "ruby $(ruby_version "$ruby"): ruby-lsp add-on link removed"
    fi
  done

  echo
  echo "Done. The ruby-lsp gem and the JetBrains Mono font were left installed."
  echo "Restart Zed. To drop the configuration itself, move ~/.config/zed away."
  exit 0
fi

if [ "$here" != "$HOME/.config/zed" ]; then
  echo "warning: expected to be at ~/.config/zed, found $here"
  echo "         Zed reads only that path; move the clone there first."
fi

chmod +x "$here"/install.sh "$here"/bin/*.sh

# Zed installs ruby-lsp for nobody: the Ruby extension looks it up on PATH under
# the Ruby a project pins, and a version without it fails silently -- no
# completion, no go to definition, nothing in the editor says why. So the gem
# goes into every Ruby, and so does the add-on: Ruby LSP loads add-ons from the
# load path, and site_ruby is on it even under Bundler. The add-on is linked as
# a file, not a directory: Ruby LSP finds add-ons with a `**` glob, which does
# not descend into symlinked directories.
found_ruby=false
for ruby in $(rubies); do
  found_ruby=true
  v=$(ruby_version "$ruby")
  if ! "$ruby" -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0"))'; then
    echo "ruby $v: skipped, ruby-lsp needs Ruby 3.0 or newer"
    continue
  fi

  gem="$(dirname "$ruby")/gem"
  if "$ruby" "$gem" list -i ruby-lsp >/dev/null 2>&1; then
    echo "ruby $v: ruby-lsp present"
  elif "$ruby" "$gem" install ruby-lsp --no-document >/dev/null 2>&1; then
    echo "ruby $v: ruby-lsp installed"
  else
    echo "ruby $v: could not install ruby-lsp (try: $gem install ruby-lsp)"
  fi

  link=$(ruby_site_addon "$ruby")
  if mkdir -p "$(dirname "$link")" 2>/dev/null && ln -sfn "$addon" "$link" 2>/dev/null; then
    echo "ruby $v: ruby-lsp add-on linked"
  else
    echo "ruby $v: cannot write $(dirname "$link") -- add-on not linked (system Ruby?)"
  fi
done
$found_ruby || echo "ruby: none found -- install one with rbenv, asdf, mise or chruby, then re-run"
command -v rbenv >/dev/null 2>&1 && rbenv rehash

# settings.json asks for JetBrains Mono, and Zed falls back without saying so
# when it is missing -- the text just looks grainy. JetBrains IDEs carry their
# own copy inside the bundled runtime and never install it system-wide, so it
# can be missing even next to RubyMine.
if fc-list 2>/dev/null | grep -qi 'JetBrains Mono' ||
   ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi jetbrainsmono; then
  echo "JetBrains Mono: installed"
else
  jb=$(ls -d /Applications/*.app/Contents/jbr/Contents/Home/lib/fonts 2>/dev/null | head -1 || true)
  if [ -n "$jb" ] && ls "$jb"/JetBrainsMono-*.ttf >/dev/null 2>&1; then
    mkdir -p "$HOME/Library/Fonts"
    cp "$jb"/JetBrainsMono-*.ttf "$HOME/Library/Fonts/"
    echo "JetBrains Mono: copied from $jb"
  elif command -v brew >/dev/null 2>&1 && brew install --cask font-jetbrains-mono >/dev/null 2>&1; then
    echo "JetBrains Mono: installed with Homebrew"
  else
    echo "JetBrains Mono: missing -- get it at https://www.jetbrains.com/lp/mono/"
    echo "  or change buffer_font_family in settings.json"
  fi
fi

# The icon theme in settings.json is the fork in extensions/. Zed indexes
# whatever sits in its extensions directory, so a link is enough.
if [ -e "$icons_link" ] && [ ! -L "$icons_link" ]; then
  echo "icon theme: $icons_link exists and is not a link -- left alone"
else
  mkdir -p "$(dirname "$icons_link")"
  ln -sfn "$here/extensions/jetbrains-icons-ruby" "$icons_link"
  echo "icon theme: linked"
fi

# The Ruby grammar cannot tell the Rails DSL from any other method call, so the
# highlighting patch lives outside the theme. It needs the Ruby extension on
# disk, which Zed installs on its first launch (auto_install_extensions).
if [ -f "$(ruby_highlights_scm)" ]; then
  "$here/bin/patch-ruby-highlights.sh" >/dev/null && echo "Ruby extension: Rails DSL patch applied"
else
  echo "Ruby extension: not installed yet -- start Zed once, then re-run this script"
fi

# Extension updates replace the Ruby grammar and drop the patch. On macOS a
# launchd agent watches for that and re-applies it.
if [ "$(uname -s)" = Darwin ]; then
  mkdir -p "$(dirname "$agent_plist")"
  sed -e "s|__ZED_DATA__|$(zed_data_dir)|g" -e "s|__CONFIG__|$here|g" \
    "$here/launchd/$agent.plist" > "$agent_plist"
  launchctl bootout "gui/$(id -u)/$agent" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$agent_plist"
  echo "launchd: $agent loaded"
else
  echo "Rails DSL patch: no watcher on this OS -- re-run bin/patch-ruby-highlights.sh"
  echo "  after Zed updates the Ruby extension"
fi

echo
echo "Done. Restart Zed. It installs the rest on first launch:"
echo "  - the extensions under auto_install_extensions (ruby, html, vue, emmet, ...)"
echo "  - herb, tailwindcss and the other language servers, on demand"
echo "  - the Claude agent, via npx, on its first thread (then run /login)"
