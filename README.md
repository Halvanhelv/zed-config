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

## The Rails DSL patch

`belongs_to`, `scope`, `has_many` and the rest read as keywords in RubyMine,
which resolves them to ActiveRecord. Tree-sitter has no such knowledge and
captures every call identically:

```scheme
(call method: [(identifier) (constant)] @function.method)
```

so no theme can separate `belongs_to` from `where` -- any colour lands on both.
`bin/patch-ruby-highlights.sh` appends an `#any-of?` list to the Ruby
extension's `highlights.scm`, in the same style the grammar already uses for
`include`/`extend`, routing the DSL to `@function.builtin`.

It edits an installed extension, so **a Zed extension update wipes it**. Re-run
the script afterwards; it is idempotent and keeps the original beside it as
`highlights.scm.orig`.

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
