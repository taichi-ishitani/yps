# frozen_string_literal: true

module YPS
  module Visitors
    using NodeExtension

    module Common
      def accept(node)
        object = super
        add_position_info(object, node)
      end

      private

      def add_position_info(object, node)
        return object if node.document? || node.mapping_key?

        pos = Position.create(node.filename, node.start_line, node.start_column)
        obj = Value.new(object, pos)
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
