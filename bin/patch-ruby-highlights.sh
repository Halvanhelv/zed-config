#!/bin/sh
# Teach Zed's Ruby grammar to paint the Rails DSL like RubyMine does.
#
# RubyMine colours belongs_to, gem, resources and friends as predefined
# methods because it resolves them to ActiveRecord, Bundler and the router;
# tree-sitter has no such knowledge and captures every call the same way:
#
#   (call method: [(identifier) (constant)] @function.method)
#
# so no theme can separate `belongs_to` from `where`. The grammar already
# solves the same problem for include/extend/prepend with an #any-of? list, and
# this appends one more in that style. Measurements off RubyMine put the DSL at
# the same orange as include (#f78b01 vs #fc8d00), so reusing @function.builtin
# gives it the right colour with no theme change.
#
# Matching is by name across every Ruby file -- the parser cannot tell a
# Gemfile from a model. Words common enough to collide with ordinary calls
# (path, default, execute, file, up, down, change, it, let, context) are left
# out on purpose.
#
# This edits an installed extension, so a Zed extension update wipes it. Re-run
# this script afterwards. Re-running also picks up new names: the original is
# kept alongside and the block is rebuilt from it every time.
set -eu

SCM="$HOME/Library/Application Support/Zed/extensions/installed/ruby/languages/ruby/highlights.scm"
MARK="; --- rails-dsl (patched by patch-ruby-highlights.sh) ---"

[ -f "$SCM" ] || { echo "not found: $SCM"; echo "Is the Ruby extension installed?"; exit 1; }

# Rebuild from the pristine copy so the list can grow between runs.
if [ -f "$SCM.orig" ]; then
  cp "$SCM.orig" "$SCM"
else
  cp "$SCM" "$SCM.orig"
fi

cat >> "$SCM" <<'SCHEME'

; --- rails-dsl (patched by patch-ruby-highlights.sh) ---
; Receiverless macros. Matching by name is the only option: they are ordinary
; method calls to the parser.
((call
  !receiver
  method: (identifier) @function.builtin)
  (#any-of? @function.builtin

    ; Attributes and Active Record associations
    "attr_accessor" "attr_reader" "attr_writer" "attribute"
    "belongs_to" "has_many" "has_one" "has_and_belongs_to_many"
    "scope" "default_scope" "enum" "delegate" "serialize" "composed_of"
    "accepts_nested_attributes_for" "has_secure_password" "has_secure_token"
    "has_one_attached" "has_many_attached" "has_rich_text"
    "store_accessor" "normalizes" "generates_token_for" "encrypts"

    ; Validations
    "validate" "validates" "validates_with" "validates_each"
    "validates_associated" "validates_presence_of" "validates_uniqueness_of"
    "validates_format_of" "validates_length_of" "validates_numericality_of"
    "validates_inclusion_of" "validates_exclusion_of"
    "validates_confirmation_of" "validates_acceptance_of"

    ; Model callbacks
    "before_validation" "after_validation"
    "before_save" "after_save" "around_save"
    "before_create" "after_create" "around_create"
    "before_update" "after_update" "around_update"
    "before_destroy" "after_destroy" "around_destroy"
    "after_commit" "after_rollback" "after_initialize" "after_find"
    "after_touch"

    ; Controllers
    "before_action" "after_action" "around_action"
    "skip_before_action" "skip_after_action"
    "helper" "helper_method" "rescue_from" "layout"
    "protect_from_forgery" "skip_forgery_protection" "respond_to"

    ; Authorization (action_policy)
    "authorize!" "allowed_to?" "verify_authorized" "skip_verify_authorized"

    ; Jobs and broadcasting
    "queue_as" "retry_on" "discard_on"
    "before_perform" "after_perform" "around_perform"
    "broadcasts_to" "broadcasts"

    ; Concerns
    "included" "prepended" "class_methods"

    ; Bundler -- Gemfile and gemspec
    "gem" "gemspec" "source" "group" "ruby" "platforms"
    "git_source" "eval_gemfile" "install_if"

    ; Routing
    "draw" "resources" "resource" "root" "namespace" "member" "collection"
    "constraints" "mount" "concern" "concerns" "defaults" "direct" "resolve"
    "get" "post" "put" "patch" "delete" "match" "redirect"

    ; Migrations
    "create_table" "change_table" "drop_table" "create_join_table"
    "add_column" "remove_column" "rename_column"
    "change_column" "change_column_null" "change_column_default"
    "add_index" "remove_index" "rename_index"
    "add_reference" "remove_reference"
    "add_foreign_key" "remove_foreign_key"
    "add_check_constraint" "remove_check_constraint"
    "enable_extension" "disable_extension" "reversible" "safety_assured"

    ; Rake
    "task" "desc"

    ; Minitest
    "test" "setup" "teardown"))

; Migration column builders: `t.string`, `t.references`, ... The receiver is
; what identifies them, so they need a rule of their own.
((call
  receiver: (identifier) @_t
  method: (identifier) @function.builtin)
  (#eq? @_t "t")
  (#any-of? @function.builtin
    "string" "text" "integer" "bigint" "float" "decimal" "numeric"
    "boolean" "binary" "date" "datetime" "time" "timestamp" "timestamps"
    "json" "jsonb" "uuid" "inet" "cidr" "macaddr" "interval" "money"
    "references" "belongs_to" "column" "index" "primary_key"
    "virtual" "vector"))
SCHEME

echo "patched: $SCM"
echo "Restart Zed for the grammar change to take effect."
