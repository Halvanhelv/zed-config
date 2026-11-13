# frozen_string_literal: true

require "ruby_lsp/addon"

module RubyLsp
  module ZedLocals
    # Brings Ruby LSP's local highlighting closer to RubyMine:
    # - colours a local where it is assigned or declared as a parameter, not
    #   only where it is read;
    # - marks a local or parameter that is never read, so Zed can grey it out.
    class Addon < ::RubyLsp::Addon
      def activate(global_state, outgoing_queue); end
      def deactivate; end
      def name = "Zed locals"
      def version = "0.2.1"

      def create_semantic_highlighting_listener(response_builder, dispatcher)
        Listener.new(response_builder, dispatcher)
      end
    end

    class Listener
      # LSP has no "unused" token modifier and Ruby LSP's legend is fixed, so an
      # unused local borrows `deprecated`. settings.json paints it grey.
      UNUSED = :deprecated

      SCOPES = %i[program def class module singleton_class block lambda].freeze

      PARAMETERS = %i[
        required_parameter optional_parameter rest_parameter
        required_keyword_parameter optional_keyword_parameter
        keyword_rest_parameter block_parameter
      ].freeze

      # `x ||= 1` and `x += 1` read the variable as well as write it.
      READ_WRITES = %i[local_variable_or_write local_variable_and_write local_variable_operator_write].freeze

      Scope = Struct.new(:declarations, :reads, :parameters, :binding)

      def initialize(response_builder, dispatcher)
        @response_builder = response_builder
        @scopes = []

        SCOPES.each do |type|
          define_singleton_method(:"on_#{type}_node_enter") { |_node| @scopes.push(Scope.new(Hash.new { |h, k| h[k] = [] }, {}, [], false)) }
          define_singleton_method(:"on_#{type}_node_leave") { |_node| mark_unused(@scopes.pop) }
        end
        PARAMETERS.each { |type| define_singleton_method(:"on_#{type}_node_enter") { |node| parameter(node) } }
        READ_WRITES.each { |type| define_singleton_method(:"on_#{type}_node_enter") { |node| read_write(node) } }

        events = SCOPES.flat_map { |type| [:"on_#{type}_node_enter", :"on_#{type}_node_leave"] } +
          (PARAMETERS + READ_WRITES).map { |type| :"on_#{type}_node_enter" }
        dispatcher.register(
          self, *events,
          :on_local_variable_write_node_enter,
          :on_local_variable_target_node_enter,
          :on_local_variable_read_node_enter,
          :on_it_local_variable_read_node_enter,
          :on_forwarding_super_node_enter,
          :on_call_node_enter,
        )
      end

      def on_local_variable_write_node_enter(node)
        declare(node, token_at(node.name_loc, :variable))
      end

      # Ruby LSP's own listener already sent a token for these (`a, b = ...`,
      # `rescue => e`), unless it sits inside a regexp with named captures.
      def on_local_variable_target_node_enter(node)
        token = @response_builder.last if @response_builder.last_token_matches?(node.location)
        declare(node, token)
      end

      def on_local_variable_read_node_enter(node)
        scope_for(node.depth)&.reads&.store(node.name, true)
      end

      def on_it_local_variable_read_node_enter(node)
        @response_builder.add_token(node.location, :parameter)
      end

      # A bare `super` passes every parameter on.
      def on_forwarding_super_node_enter(_node)
        scope = @scopes.reverse_each.find { |s| s.parameters.any? }
        scope&.parameters&.each { |name| scope.reads[name] = true }
      end

      # `binding` can reach any local, so nothing in that scope is unused.
      def on_call_node_enter(node)
        return unless node.name == :binding && !node.receiver

        @scopes.each { |scope| scope.binding = true }
      end

      private

      def parameter(node)
        location = node.respond_to?(:name_loc) ? node.name_loc : node.location
        return unless location && node.name

        token = token_at(location.copy(length: node.name.length), :parameter)
        @scopes.last&.parameters&.push(node.name)
        @scopes.last&.declarations&.[](node.name)&.push(token)
      end

      def read_write(node)
        scope = scope_for(node.depth)
        scope&.reads&.store(node.name, true)
        token_at(node.name_loc, :variable)
      end

      def declare(node, token)
        scope_for(node.depth)&.declarations&.[](node.name)&.push(token)
      end

      # Ruby LSP's listener runs first; when it already marked this spot (a
      # reassigned parameter), keep its token instead of adding another.
      def token_at(location, type)
        @response_builder.add_token(location, type) unless @response_builder.last_token_matches?(location)
        @response_builder.last
      end

      def scope_for(depth)
        @scopes[-1 - depth] if depth < @scopes.size
      end

      def mark_unused(scope)
        return if scope.nil? || scope.binding

        scope.declarations.each do |name, tokens|
          next if scope.reads[name] || name.start_with?("_")

          tokens.compact.each do |token|
            modifiers = token.modifier.filter_map { |index| ResponseBuilders::SemanticHighlighting::TOKEN_MODIFIERS.key(index) }
            token.replace_modifier(modifiers | [UNUSED])
          end
        end
      end
    end
  end
end
