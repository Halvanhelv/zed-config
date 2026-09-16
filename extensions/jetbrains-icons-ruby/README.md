# JetBrains Icons + Ruby

A fork of [ziishaned/zed-jetbrains-icons](https://github.com/ziishaned/zed-jetbrains-icons)
(v0.0.3), whose theme ships an `icons/dark/ruby.svg` but never maps a suffix to
it. Ruby and Rails files therefore fall back to the generic icon.

This copy adds the missing mappings and nothing else:

- `rb`, `rake`, `gemspec`, `ru`, `rbs`, `rbi`, `jbuilder`, `arb` → `ruby`
- `erb`, `haml`, `slim` → `html`
- stems `Gemfile`, `Rakefile`, `Procfile`, `Guardfile`, `Capfile`, `Brewfile`,
  `Appraisals`, `Dangerfile`, `Fastfile` → `ruby`, `Dockerfile` → `docker`

The upstream theme has no Rails-specific artwork, so everything Ruby-shaped
shares one glyph. Distinguishing them would mean drawing new SVGs.

The SVGs under `icons/` are the upstream ones, unmodified.

## Install

Zed indexes whatever sits in its extensions directory, so a symlink is enough:

    ln -sfn ~/.config/zed/extensions/jetbrains-icons-ruby \
      ~/Library/Application\ Support/Zed/extensions/installed/jetbrains-icons-ruby

Then restart Zed and pick **JetBrains Icons + Ruby Dark**. Editing the theme
JSON here takes effect on the next restart -- no reinstall.
