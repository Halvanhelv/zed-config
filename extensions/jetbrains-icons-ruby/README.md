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

The SVGs under `icons/` are the upstream ones, unmodified, except the
`rails-*.svg` files: those are IntelliJ Community icons (Apache 2.0, see the
repository README), used through `file_patterns` for Rails models,
controllers, helpers, jobs, mailers, migrations and tests.

## Install

`install.sh` at the repository root links this directory into Zed's
extensions directory, since Zed indexes whatever sits there. Restart Zed and
pick **JetBrains Icons + Ruby Dark** (settings.json already does). Editing the
theme JSON here takes effect on the next restart -- no reinstall.

## License

Apache 2.0, as upstream; see `LICENSE`.
