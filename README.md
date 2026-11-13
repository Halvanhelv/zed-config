# Zed for RubyMine users

A complete `~/.config/zed` that makes [Zed](https://zed.dev) look and behave
like RubyMine for Ruby and Rails work: the JetBrains keymap with its gaps
filled, a Darcula theme with colours measured off RubyMine, and ruby-lsp
tuned until highlighting, navigation and tests feel the same.

What you get on top of a stock Zed:

- **RubyMine's Darcula colours**, including the Rails DSL (`has_many`,
  `validates`, `before_action`) in RubyMine's brighter orange.
- **Locals that look like RubyMine's**: every occurrence of a local variable or
  parameter in the same colour, and the unused ones greyed out.
- **Green run arrows beside tests** that run that one test (Minitest or RSpec),
  `ctrl+R` to rerun, and `cmd+shift+T` to jump between a class and its test.
- **RubyMine keys** that the JetBrains base keymap gets wrong or leaves out.
- **Sticky lines and parameter info popups**, which Zed ships turned off.
- **JetBrains file icons** with the Ruby mappings the upstream theme lacks,
  and IntelliJ's own icons for Rails models, controllers, helpers, jobs,
  mailers, migrations and tests (needs a Zed build with `file_patterns`, see
  below).

## Requirements

- macOS or Linux, see [Platforms](#platforms).
- Zed, with its command line tool (`zed: install cli` from the command palette).
- Ruby 3.0 or newer, from rbenv, asdf, mise, chruby or your system.
- git.

## Install

The repository *is* the configuration directory, so installing means cloning it
to `~/.config/zed` (`$XDG_CONFIG_HOME/zed` on Linux if you set that). Move an
existing configuration out of the way first:

```sh
[ -e ~/.config/zed ] && mv ~/.config/zed ~/.config/zed.before-zed-config
git clone https://github.com/Halvanhelv/zed-config.git ~/.config/zed
```

Start Zed once and wait for it to install the extensions it lists under
`auto_install_extensions` (Ruby among them). Then run the installer and restart
Zed:

```sh
~/.config/zed/install.sh
```

The installer is safe to run again at any time, prints each step, and changes
only these things:

- for every Ruby 3.0+ it finds: installs the `ruby-lsp` gem if missing, and
  links this repository's ruby-lsp add-on into that Ruby's `site_ruby`;
- installs the JetBrains Mono font if missing (copied from an installed
  JetBrains IDE, through Homebrew, or on Linux from JetBrains' release);
- links `extensions/jetbrains-icons-ruby` into Zed's extensions directory;
- patches the Ruby extension's `highlights.scm` for the Rails DSL;
- on macOS, loads a launchd agent that re-applies that patch after Zed updates
  the extension.

Your projects are never touched.

**Fork it if you plan to change things.** Settings you will likely want to
adjust: `theme`, `buffer_font_size`, `ui_font_size`, and the `agent` section.

## Update

```sh
git -C ~/.config/zed pull
~/.config/zed/install.sh
```

Run the installer again after installing a new Ruby, so it gets ruby-lsp and the
add-on too.

## Uninstall

```sh
~/.config/zed/install.sh --uninstall
mv ~/.config/zed ~/.config/zed.removed
```

The first command removes the launchd agent, the add-on links, the icon theme
link and the grammar patch. It leaves the ruby-lsp gem and the font installed.

## Platforms

**macOS** is where it is used daily.

**Linux** is tested in an Ubuntu 24.04 container with Ruby 3.2, and the
ruby-lsp add-on also on Ruby 3.0: the installer (font from JetBrains' release
included), uninstall, the ruby-lsp add-on, the test runner for Minitest and
RSpec, go to test with the `zeditor` command, and a custom `$XDG_CONFIG_HOME`.
The scripts find Zed's data under `$XDG_DATA_HOME/zed` and notify through
`notify-send` when it is present. Two differences:

- No watcher for extension updates: re-run `bin/patch-ruby-highlights.sh`
  after Zed updates the Ruby extension.
- Zed installed as a Flatpak keeps its data inside the sandbox; the scripts do
  not look there.

The key bindings follow RubyMine's macOS keymap on macOS and its Windows/Linux
keymap on Linux; see the table below.

## What is here

| Path | Holds |
|---|---|
| `settings.json` | theme, fonts, docks, language servers, agents, tabs |
| `keymap.json` | overrides on top of the JetBrains base keymap |
| `tasks.json` | the `Go to test` task and the gutter test runner |
| `themes/darcula-rubymine.json` | the Darcula RubyMine theme |
| `extensions/jetbrains-icons-ruby/` | the JetBrains icon theme with Ruby mappings |
| `ruby-lsp/` | the ruby-lsp add-on for local variable highlighting |
| `bin/goto-test.sh` | source ↔ test jump used by `Go to test` |
| `bin/run-test.sh` | runs the test under a gutter arrow |
| `bin/patch-ruby-highlights.sh` | Rails DSL highlighting, patched into the Ruby extension |
| `bin/_common.sh` | what differs between macOS and Linux, for the scripts above |
| `launchd/` | the agent that re-applies the patch after an extension update |
| `install.sh` | sets up and removes everything a clone cannot carry |

Zed's `embeddings/`, `prompts/`, `conversations/` and `settings_backup.json`
are ignored: they are state Zed writes for itself.

## The JetBrains keymap

`"base_keymap": "JetBrains"` does the heavy lifting -- double shift, go to
definition, find usages, rename, reformat, the tool windows and the debugger
keys all match RubyMine already. `keymap.json` only fills gaps, using
`secondary-` (cmd on macOS, ctrl on Linux) where RubyMine's two keymaps agree
and an `os == ...` context where they differ:

| macOS | Linux | Action | Why |
|---|---|---|---|
| `shift shift` | `shift shift` | file finder | the base layer sent it to the command palette, where find-action already goes |
| `cmd+shift+T` | `ctrl+shift+T` | `Go to test` task | Zed has no go-to-test |
| `cmd+alt+↓` / `↑` | `ctrl+alt+↓` / `↑` | next / previous reference | steps through usages without opening a multibuffer |
| `cmd+alt+A` | `ctrl+alt+A` | agent panel | unbound by the base layer |
| `ctrl+R` | `ctrl+F5` (base layer) | rerun last task | RubyMine's Rerun on each OS |
| `ctrl+cmd+G` | `ctrl+alt+shift+J` | select all occurrences | RubyMine's key on each OS |
| `cmd+-` / `cmd++` | `ctrl+-` / `ctrl+=` (Zed's own) | font size | on macOS the base layer folds code on them; folding stays on `cmd+alt+[` / `]` |
| `cmd+shift+0` | `ctrl+0` (Zed's own) | reset font size | on macOS the base layer took `cmd+0` for the git panel |
| `cmd+alt+V` / `H` | -- | split right / down | on Linux `ctrl+alt+H` is the call hierarchy |
| `ctrl+cmd+B` | -- | left dock | on macOS `cmd+B` went to Go to Definition |

Zooming with `cmd` and the scroll wheel is off (`mouse_wheel_zoom`): a
two-finger swipe with `cmd` held changed the font size by accident.

## JetBrains Mono is not optional

JetBrains IDEs ship the font inside their bundled runtime
(`*.app/Contents/jbr/Contents/Home/lib/fonts/`) and never install it
system-wide, so it can be missing from `~/Library/Fonts` while RubyMine renders
with it happily. Zed then falls back without saying so, and the result reads as
grainy text rather than as a missing font. `install.sh` installs it.

Ligatures are off (`buffer_font_features`), matching RubyMine, so `->` stays
two glyphs instead of becoming an arrow.

## The Rails DSL patch

`belongs_to`, `gem`, `resources` and the rest read as keywords in RubyMine,
which resolves them to ActiveRecord, Bundler and the router. Tree-sitter has no
such knowledge and captures every call identically:

```scheme
(call method: [(identifier) (constant)] @function.method)
```

so no theme can separate `belongs_to` from `where` -- any colour lands on both.
`bin/patch-ruby-highlights.sh` appends an `#any-of?` list to the Ruby
extension's `highlights.scm`, in the same style the grammar already uses for
`include`/`extend`, routing the DSL to `@function.builtin`.

The list covers associations, validations, callbacks, controller and job
macros, the Bundler DSL, the router, migrations and `t.string`-style column
builders. Matching is by name across every Ruby file -- the parser cannot tell
a Gemfile from a model -- so names common enough to collide with ordinary calls
(`path`, `default`, `execute`, `file`, `up`, `down`, `change`) are left out.

It edits an installed extension, so **a Zed extension update wipes it**, and
nothing in the editor says so: the DSL just goes back to the plain call colour.
On macOS a launchd agent (`launchd/zed-config.patch-ruby-highlights.plist`)
watches the extension on disk and runs the script with `--if-needed`, which
patches only a file that lost the patch and posts a notification asking for a
Zed restart. Its log is `/tmp/zed-config.patch-ruby-highlights.log`.

A `highlights.scm` without the patch is taken as the new pristine copy
(`highlights.scm.orig`); a patched one is rebuilt from that copy, so a manual
re-run also picks up names added since.

## Highlighting from the language server

Tree-sitter cannot tell a local variable from a receiverless method call --
both are bare identifiers. ruby-lsp can, so `semantic_tokens` is `combined`:
tree-sitter paints the base, the server corrects it. `document_folding_ranges`
is on globally (it falls back to tree-sitter when the server returns nothing)
and `document_symbols` only for Ruby, because enabling it turns tree-sitter
symbols off entirely and would empty the outline for Markdown and anything else
without a server.

ruby-lsp reports every receiverless call without parentheses as `method`,
`has_many` included, which in `combined` mode wiped out the Rails DSL colours
-- so `method` is switched off with an empty semantic token rule and
tree-sitter paints calls again. The gaps it leaves on locals are covered by the
add-on below.

Its inlay hints are off until `featuresConfiguration.inlayHint` asks for them,
and even then it only knows the implicit `rescue StandardError` and the value
behind a shorthand hash key. Only the rescue one is on here; RubyMine does not
repeat a shorthand hash value, so neither do we.

RubyMine's parameter-name hints, the `name` and `**options` it draws inside a
call, are out of reach: Shopify closed the inlay hints issue saying parameter
names are "covered by signature help" and not an inlay hint's job.

## Locals coloured everywhere, unused ones greyed

`ruby-lsp` sends a semantic token for a local where it is read, but not where
it is assigned (`total = 0`, `x ||= 1`, `x += 1`), nor for parameter names in
a signature, nor for `it`. In `combined` mode those spots fall back to
tree-sitter, so one variable showed in two colours: `a, b = ...` was coloured
while `a = ...` was not.

`ruby-lsp/lib/ruby_lsp/zed_locals/addon.rb` is a Ruby LSP add-on that sends
the missing tokens. Ruby LSP loads add-ons it finds on the load path, and every
Ruby's `site_ruby` directory is on the load path even under Bundler, so
`install.sh` links the add-on there. It links the file rather than its
directory: Ruby LSP looks for add-ons with a `**` glob, which does not descend
into symlinked directories.

It also greys out what RubyMine greys out: a local or parameter that is never
read. Prism records on every read and write how many scopes up the variable
lives (`depth`), so each read lands on the right `def` or block; when a scope
ends, its unread names are marked. A bare `super` reads every parameter,
`binding` exempts the whole scope, and `_`-prefixed names are skipped. The
add-on runs inside whatever Ruby the project uses, so it sticks to Ruby 3.0
syntax. LSP has
no "unused" modifier and Ruby LSP's legend is fixed, so the add-on borrows
`deprecated`, and two `semantic_token_rules` paint it `#808080` italic. On
400 files of a real Rails app it flagged three spots, all genuinely unused.

To see what the server actually sends for a file, use
`dev: open highlights tree view` in Zed.

## Colours measured, not guessed

Screenshots do not carry the theme's hex values: the capture shifts them. Every
colour here was recovered by calibrating on six known pairs (theme value
against its pixel in a Zed screenshot), fitting a per-channel curve and
inverting it over the RubyMine shot; the calibration round-trips its own
anchors exactly. What that turned up:

| Role | RubyMine | Note |
|------|----------|------|
| keywords (`module`, `def`) | `#cc7832` | matched already |
| predefined methods (`extend`, `has_many`) | `#fc9806` | a *second*, brighter orange |
| local variables and parameters | `#d4b021` italic | not the `#ffc66d` of method names |
| symbols and hash keys | `#89a6ae` | theme had `#769aa5` |
| numbers | `#74a4c8` | theme had `#6897bb` |
| comma | `#cc7832` | but `.` and `::` stay default |

A screen recording is not a substitute: H.264 stores chroma at quarter
resolution and code glyphs are thinner than that grid.

## Ruby: the trap worth knowing

Zed never installs `ruby-lsp`. The Ruby extension looks it up on `PATH` under
the Ruby each project pins, and a project on a version that lacks it fails with
`ruby-lsp: command not found` -- in the log only. The editor shows no error, it
simply has no completion, no go to definition and no find usages, which reads
like Zed being broken rather than a missing gem. That is why `install.sh`
installs it into every Ruby it finds; re-run it after adding a Ruby.

`ruby-lsp` then builds its own bundle under `.ruby-lsp/` in each project and
pulls in `ruby-lsp-rails` on its own; that directory git-ignores itself.

`languages.Ruby.language_servers` lists servers explicitly rather than ending
with `"..."`. The wildcard also starts sorbet, steep, fuzzy-ruby-server and
kanayago -- the last one tries to compile a native gem on every launch and
fails.

Formatting is pinned to `rubocop`, since ruby-lsp advertises it too and the
winner would otherwise be arbitrary. `ruby-lsp`'s own diagnostics are off
because rubocop's language server already reports them.

## RubyMine habits switched on

- `auto_signature_help`: parameter info pops up inside a call's parentheses,
  as RubyMine's does. Zed ships it off.
- `sticky_scroll`: the enclosing `class` and `def` stay pinned to the top while
  scrolling, RubyMine's sticky lines. Zed ships it off.

What cannot be matched: `shift+F6` renames constants only, because ruby-lsp's
rename handles constants and nothing else and an add-on has no hook for it; for
a local, `ctrl+cmd+G` selects every occurrence. ruby-lsp's code lenses
(`Run | Debug` above tests) call VS Code commands, so `code_lens` stays off; the
gutter arrows do that job. Zed has no peek popup (`cmd+Y`), no clipboard
history and no complete-statement.

## Run the test under the cursor

The Ruby extension puts a green arrow beside every `test "..."`, `def test_`,
test class and RSpec example, tagged `ruby-test` -- but an arrow runs nothing
until some task claims that tag. The `test ...` task in `tasks.json` does,
through `bin/run-test.sh`; `ctrl+R` reruns it.

Minitest runs by name (`-n test_...`, the method name Rails derives from the
string), not by line: with minitest 6, Rails 8.1 ignores the `file:line`
filter and runs the whole file. An arrow on a class line runs the whole file;
RSpec gets `file:line`. The project root is the nearest directory with a
Gemfile.

The tasks reach the scripts through a small `sh -c` rather than a plain path:
Zed quotes the command of a task that has arguments, so a `$HOME` in it would
never be expanded, and an absolute path would tie the file to one machine. The
`sh -c` also honours `$XDG_CONFIG_HOME` -- spelled out as an `if`, because Zed
applies a `${VAR:-default}` itself before the shell ever runs, ignoring the
variable.

## Go to test

`cmd+shift+T` swaps between `app/…/x.rb` and `test/…/x_test.rb` (or
`spec/…/x_spec.rb`, whichever exists) in both directions, substituting on the
first `/app/`, `/test/` or `/spec/` segment so it also works when the Rails
root is not the worktree root.

The terminal tab it spawns flashes and closes. That is structural: Zed creates
a terminal item for every task, and `reveal: "never"` only stops it taking
focus. Failures go to a desktop notification instead, since nothing printed in
that tab would be read.

## Tailwind in ERB

`.html.erb` is the language **HTML+ERB**, not ERB, and Zed's Tailwind server is
opt-in -- the Ruby extension does not subscribe either one to it. Hence the
explicit `languages["HTML+ERB"].language_servers`.

A project holding two Tailwind versions at once (a v4 CSS-first entrypoint for
server-rendered views next to a v3 `tailwind.config.js` for the frontend) gets
one language server for the worktree, and which config it binds to in an ERB
buffer is worth checking by eye before trusting the completions.

## Claude agent

Registered under `agent_servers` as a custom entry pinned to a version. The
alternative is Zed's own registry (`zed: acp registry`), which manages updates
-- **use one or the other**, or the agent appears twice in the menu.

It authenticates separately from Zed's built-in agent: open a thread and run
`/login`. An Anthropic key configured for Zed does not carry over.

## Rails file icons

The icon theme marks Rails files by their path, with icons from
[IntelliJ Community](https://github.com/JetBrains/intellij-community)
(`platform/icons/src/expui`, Apache 2.0, taken at `b7a082509f`):

| Files | Icon |
|---|---|
| `app/models/**` | `nodes/modelClass` |
| `*_controller.rb` | `nodes/controller` |
| `app/mailers/**`, `*_mailer.rb` | the controller's class base with an envelope |
| `app/helpers/**` | a module: the class circle in green with an M |
| `app/jobs/**`, `*_job.rb`, `db/migrate/*.rb` | `nodes/class` |
| `*_test.rb` | the Ruby glyph with `nodes/junitTestMark` |
| `*_spec.rb` | the same in blue |

These follow what RubyMine shows for each kind of file, built from open
IntelliJ parts only. RubyMine's own Rails icons live in its closed-source Ruby plugin, so they are
not used here. Tests come first in `file_patterns`, so
`spec/models/user_spec.rb` is a test, not a model.

Picking an icon by path needs `file_patterns` in icon themes, proposed to Zed
in [zed-industries/zed#66949](https://github.com/zed-industries/zed/pull/66949).
A Zed without it ignores the section and shows the plain Ruby icon.

## License

MIT, see [LICENSE](LICENSE). `extensions/jetbrains-icons-ruby` is a fork of
[ziishaned/zed-jetbrains-icons](https://github.com/ziishaned/zed-jetbrains-icons)
and keeps its Apache 2.0 license, in that directory's `LICENSE`.
