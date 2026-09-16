# Zed configuration

My `~/.config/zed`, versioned in place. Cloning it to that path restores the
editor as it stands; nothing is copied anywhere.

```sh
git clone git@github.com:Halvanhelv/zed-config.git ~/.config/zed
~/.config/zed/install.sh
```

## What is here

| File | Holds |
|---|---|
| `settings.json` | theme, fonts, docks, language servers, agents, tabs |
| `keymap.json` | overrides on top of the JetBrains base keymap |
| `tasks.json` | the `Go to test` task |
| `bin/goto-test.sh` | source ↔ test jump used by that task |

Zed's `embeddings/`, `prompts/` and `conversations/` are ignored: they are
local LMDB stores it rebuilds by itself.

## The JetBrains keymap

`"base_keymap": "JetBrains"` does the heavy lifting -- `shift shift`, `cmd+B`,
`alt+F7`, `shift+F6`, `cmd+alt+L`, the `cmd+1/7/0` tool windows and the
debugger F-keys all match RubyMine already. `keymap.json` only fills gaps:

| Keys | Action | Why |
|---|---|---|
| `shift shift` | file finder | the base layer sent it to the command palette, where `cmd+shift+A` already goes |
| `cmd+shift+T` | `Go to test` task | Zed has no go-to-test; this key is otherwise "reopen closed tab" |
| `cmd+alt+↓` / `↑` | next / previous reference | steps through usages without opening a multibuffer |
| `ctrl+R` | rerun last task | RubyMine's Run |
| `cmd+alt+A` | agent panel | unbound by the base layer |
| `cmd+alt+V` / `H` | split right / down | RubyMine has no shortcut for it |
| `ctrl+cmd+B` | left dock | `cmd+B` went to Go to Definition |

## JetBrains Mono is not optional

JetBrains IDEs ship the font inside their bundled runtime
(`*.app/Contents/jbr/Contents/Home/lib/fonts/`) and never install it
system-wide, so it can be missing from `~/Library/Fonts` while RubyMine renders
with it happily. Zed then falls back without saying so, and the result reads as
grainy text rather than as a missing font. `install.sh` copies it out of any
JetBrains IDE it finds.

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

It edits an installed extension, so **a Zed extension update wipes it**. Re-run
the script afterwards. It keeps the original beside it as `highlights.scm.orig`
and rebuilds the block from that copy every run, so re-running also picks up
names added since.

## Highlighting from the language server

Tree-sitter cannot tell a local variable from a receiverless method call --
both are bare identifiers. ruby-lsp can, so `semantic_tokens` is `combined`:
tree-sitter paints the base, the server corrects it. `document_folding_ranges`
is on globally (it falls back to tree-sitter when the server returns nothing)
and `document_symbols` only for Ruby, because enabling it turns tree-sitter
symbols off entirely and would empty the outline for Markdown and anything else
without a server.

Two gaps worth knowing. ruby-lsp emits no token for the *declaration* of a
local variable, only for its uses, so `tally = ...` falls back to tree-sitter
while `tally` on the next line comes from the server; the grammar patch adds an
`(assignment left: ...)` rule and both land on the same colour. And it reports
every call as `method`, `has_many` included, which in `combined` mode wiped out
the Rails DSL colours -- so `method` is switched off with an empty semantic
token rule and tree-sitter paints calls again.

Its inlay hints are off until `featuresConfiguration.inlayHint` asks for them,
and even then it only knows the implicit `rescue StandardError` and the value
behind a shorthand hash key -- the listener registers exactly two handlers,
`on_rescue_node_enter` and `on_implicit_node_enter`, on main as well as in the
installed gem. Only the rescue one is on here; RubyMine does not repeat a
shorthand hash value, so neither do we.

RubyMine's parameter-name hints, the `name` and `**options` it draws inside a
call, are therefore out of reach, and not as a matter of waiting: Shopify
closed the inlay hints issue saying parameter names are "covered by signature
help" and not an inlay hint's job. Lines will stay shorter here than in
RubyMine, with identical code.

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
resolution and code glyphs are thinner than that grid. Recovering known Zed
colours from a 1512x982 capture missed by 28 to 95 units -- more than the
distance between the colours being told apart.

Two RubyMine habits have no counterpart and are not worth hunting for: Zed has
no peek popup (`cmd+Y`), no clipboard history, no complete-statement, and one
symbol picker rather than separate class and symbol ones.

## Ruby: the trap worth remembering

`ruby-lsp` is resolved from `PATH` and Zed never installs it. It has to be
present under **every Ruby version a project pins**, because a project on a
version that lacks it fails with `rbenv: ruby-lsp: command not found` -- in the
log only. The editor shows no error, it simply has no completion, no go to
definition and no find usages, which reads like Zed being broken rather than a
missing gem.

```sh
RBENV_VERSION=4.0.4 gem install ruby-lsp && rbenv rehash
```

`ruby-lsp` then builds its own bundle under `.ruby-lsp/` and pulls in
`ruby-lsp-rails` on its own; that directory git-ignores itself.

`languages.Ruby.language_servers` lists servers explicitly rather than ending
with `"..."`. The wildcard also starts sorbet, steep, fuzzy-ruby-server and
kanayago -- the last one tries to compile a native gem on every launch and
fails.

Formatting is pinned to `rubocop`, since ruby-lsp advertises it too and the
winner would otherwise be arbitrary. `ruby-lsp`'s own diagnostics are off
because rubocop's language server already reports them.

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

## Go to test

`cmd+shift+T` swaps between `app/…/x.rb` and `test/…/x_test.rb` in both
directions, substituting on the first `/app/` or `/test/` segment so it also
works when the Rails root is not the worktree root.

The terminal tab it spawns flashes and closes. That is structural: Zed creates
a terminal item for every task, and `reveal: "never"` only stops it taking
focus. Failures go to Notification Center instead, since nothing printed in
that tab would be read.
