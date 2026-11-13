# frozen_string_literal: true

require "ruby_lsp/addon"

module RubyLsp
  module ZedLocals
    # Ruby LSP colours a local where it is read but not where it is assigned or
    # declared as a parameter. Fill those gaps so every occurrence looks the same.
    class Addon < ::RubyLsp::Addon
      def activate(global_state, outgoing_queue); end
      def deactivate; end
      def name = "Zed locals"
      def version = "0.1.0"

      def create_semantic_highlighting_listener(response_builder, dispatcher)
        Listener.new(response_builder, dispatcher)
      end
    end

    class Listener
      PARAMETERS = %i[
        required_parameter optional_parameter rest_parameter
        required_keyword_parameter optional_keyword_parameter
        keyword_rest_parameter block_parameter
      ].freeze

      WRITES = %i[
        local_variable_write local_variable_or_write
        local_variable_and_write local_variable_operator_write
      ].freeze

      def initialize(response_builder, dispatcher)
        @response_builder = response_builder
        events = (PARAMETERS + WRITES).map { :"on_#{it}_node_enter" }
        dispatcher.register(self, *events, :on_it_local_variable_read_node_enter)
        PARAMETERS.each { define_singleton_method(:"on_#{it}_node_enter") { |node| parameter(node) } }
        WRITES.each { define_singleton_method(:"on_#{it}_node_enter") { |node| write(node) } }
      end

      def on_it_local_variable_read_node_enter(node)
        @response_builder.add_token(node.location, :parameter)
      end

      private

      def parameter(node)
        location = node.respond_to?(:name_loc) ? node.name_loc : node.location
        return unless location && node.name

        @response_builder.add_token(location.copy(length: node.name.length), :parameter)
      end

      # Ruby LSP's own listener runs first and already marks a parameter that is reassigned.
      def write(node)
        return if @response_builder.last_token_matches?(node.name_loc)

        @response_builder.add_token(node.name_loc, :variable)
      end
    end
  end
end
