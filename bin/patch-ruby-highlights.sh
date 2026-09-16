#!/bin/sh
# Teach Zed's Ruby grammar to paint the Rails DSL like RubyMine does.
#
# RubyMine colours belongs_to, has_many, scope and friends as predefined
# methods because it resolves them to ActiveRecord; tree-sitter has no such
# knowledge and captures every call the same way:
#
#   (call method: [(identifier) (constant)] @function.method)
#
# so no theme can separate `belongs_to` from `where`. The grammar already
# solves the same problem for include/extend/prepend with an #any-of? list, and
# this appends one more in that style. Measurements off RubyMine put the DSL at
# the same orange as include (#f78b01 vs #fc8d00), so reusing @function.builtin
# gives it the right colour with no theme change.
#
# This edits an installed extension, so a Zed extension update wipes it. Re-run
# this script afterwards; it is idempotent.
set -eu

SCM="$HOME/Library/Application Support/Zed/extensions/installed/ruby/languages/ruby/highlights.scm"
MARK="; --- rails-dsl (patched by patch-ruby-highlights.sh) ---"

[ -f "$SCM" ] || { echo "not found: $SCM"; echo "Is the Ruby extension installed?"; exit 1; }

if grep -qF "$MARK" "$SCM"; then
  echo "already patched: $SCM"
  exit 0
fi

cp "$SCM" "$SCM.orig" 2>/dev/null || true

cat >> "$SCM" <<'SCHEME'

; --- rails-dsl (patched by patch-ruby-highlights.sh) ---
; Receiverless class-body macros. Matching by name is the only option: they are
; ordinary method calls to the parser.
((call
  !receiver
  method: (identifier) @function.builtin)
  (#any-of? @function.builtin
    "attr_accessor" "attr_reader" "attr_writer" "attribute"
    "belongs_to" "has_many" "has_one" "has_and_belongs_to_many"
    "scope" "default_scope" "enum" "delegate" "serialize"
    "validate" "validates" "validates_presence_of" "validates_uniqueness_of"
    "accepts_nested_attributes_for" "has_secure_password"
    "has_one_attached" "has_many_attached"
    "before_validation" "after_validation"
    "before_save" "after_save" "around_save"
    "before_create" "after_create" "around_create"
    "before_update" "after_update" "around_update"
    "before_destroy" "after_destroy" "around_destroy"
    "after_commit" "after_rollback" "after_initialize" "after_find"
    "before_action" "after_action" "around_action"
    "skip_before_action" "skip_after_action"
    "helper_method" "rescue_from" "layout" "protect_from_forgery"
    "queue_as" "retry_on" "discard_on"
    "broadcasts_to" "broadcasts"))
SCHEME

echo "patched: $SCM"
echo "Restart Zed for the grammar change to take effect."
