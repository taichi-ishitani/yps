# frozen_string_literal: true

module YPS
  module Visitors
    using NodeExtension

    module Common
      def initialize(scanner, class_loader, value_class, symbolize_names:, freeze:)
        super(scanner, class_loader, symbolize_names:, freeze:)
        @value_class = value_class
      end

      def accept(node)
        object = super
        create_wrapped_object(object, node)
      end

      private

      def create_wrapped_object(object, node)
        return object if node.document? || node.mapping_key?

        pos = Position.create(node.filename, node.start_line, node.start_column)
        obj = @value_class.new(object, pos)
        @freeze && obj.freeze || obj
      end
    end

    class ToRuby < Psych::Visitors::ToRuby
      include Common
    end

    class NoAliasRuby < Psych::Visitors::NoAliasRuby
      include Common
    end
  end
end
