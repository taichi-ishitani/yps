# frozen_string_literal: true

module YPS # :nodoc: all
  module Visitor
    using NodeExtension

    module Common
      def initialize( # rubocop:disable Metrics/ParameterLists
        scanner, class_loader, unwrapped_classes, value_class,
        symbolize_names:, freeze:
      )
        super(scanner, class_loader, symbolize_names:, freeze:)
        @unwrapped_classes = unwrapped_classes
        @value_class = value_class
      end

      def accept(node)
        object = super
        if unwrap?(object, node)
          object
        else
          create_wrapped_object(object, node)
        end
      end

      private

      def create_wrapped_object(object, node)
        pos = Position.new(node.filename, node.start_line + 1, node.start_column + 1)
        obj = @value_class.new(object, pos)
        @freeze && obj.freeze || obj
      end

      def unwrap?(object, node)
        node.document? ||
          node.mapping_key? ||
          @unwrapped_classes.any? { |klass| object.instance_of?(klass) }
      end
    end

    class ToRuby < Psych::Visitors::ToRuby
      include Common
    end

    class NoAliasRuby < Psych::Visitors::NoAliasRuby
      include Common
    end

    def self.create( # rubocop:disable Metrics/ParameterLists
      permitted_classes, permitted_symbols, unwrapped_classes,
      aliases, symbolize_names, freeze, strict_integer, value_class
    )
      class_loader = Psych::ClassLoader::Restricted.new(
        permitted_classes.map(&:to_s), permitted_symbols.map(&:to_s)
      )
      scanner =
        if RUBY_VERSION >= '3.2.0'
          Psych::ScalarScanner.new(class_loader, strict_integer:)
        else
          Psych::ScalarScanner.new(class_loader)
        end
      (aliases && ToRuby || NoAliasRuby)
        .new(scanner, class_loader, unwrapped_classes, value_class, symbolize_names:, freeze:)
    end
  end
end
