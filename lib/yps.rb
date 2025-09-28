# frozen_string_literal: true

require 'delegate'
require 'psych'

require_relative 'yps/version'
require_relative 'yps/value'
require_relative 'yps/node_extension'
require_relative 'yps/parser'
require_relative 'yps/visitors'

module YPS
  class << self
    def load( # rubocop:disable Metrics/ParameterLists
      yaml,
      permitted_classes: [], permitted_symbols: [], aliases: false, filename: nil,
      fallback: nil, symbolize_names: false, freeze: false, strict_integer: false
    )
      result = parse(yaml, filename)
      return fallback unless result

      class_loader =
        Psych::ClassLoader::Restricted.new(
          permitted_classes.map(&:to_s), permitted_symbols.map(&:to_s)
        )
      scanner =
        if RUBY_VERSION >= '3.2.0'
          Psych::ScalarScanner.new(class_loader, strict_integer:)
        else
          Psych::ScalarScanner.new(class_loader)
        end
      visitor =
        if aliases
          Visitors::ToRuby.new(scanner, class_loader, symbolize_names:, freeze:)
        else
          Visitors::NoAliasRuby.new(scanner, class_loader, symbolize_names:, freeze:)
        end

      visitor.accept(result)
    end

    private

    def parse(yaml, filename)
      Parser
        .new { |node| return node }
        .parse(yaml, filename)

      false
    end
  end
end
