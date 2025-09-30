# frozen_string_literal: true

require 'delegate'
require 'psych'

require_relative 'yps/version'
require_relative 'yps/value'
require_relative 'yps/node_extension'
require_relative 'yps/parser'
require_relative 'yps/visitors'

##
# = YPS: YAML Positioning Sysmte
#
# YPS is a gem to parse YAML and
# add position information (file name, line and column) to each parsed elements.
# This is useful for error reporting and debugging,
# allowing developers to precisely locate an issue within the original YAML file.
module YPS
  class << self
    ##
    # Safely load the YAML string in +yaml+ and add position information (file name line and column)
    # to each parsed objects except for hash keys.
    #
    # Parsed objects will be wrapped by YPS::Value class to add the accessor returning the position information.
    # You can use the +value_class+ to specify your own wrapper class.
    #
    # Classes which are allowed to be loaded by default are same
    # as the Psych.safe_load[https://docs.ruby-lang.org/en/master/Psych.html#method-c-safe_load] method.
    #
    # Arguments:
    # +yaml+::
    #   String or IO object containing the YAML string to be parsed.
    # +permitted_classes+::
    #   Array containing additional classes allowed to be loaded.
    # +permitted_symbols+::
    #   Array containing Symbols allowed to be loaded. By default, any symbol can be loaded.
    # +aliases+::
    #   Aliases can be used if set to true. By default, aliases are not allowed.
    # +filename+::
    #   File name string which will be added to the position information of each parsed object.
    # +fallback+::
    #   An object which will be returned when an empty YAML string is given.
    # +symbolize_names+::
    #   All hash keys will be symbolized if set to true.
    # +freeze+::
    #   All parsed objects will be frozen if set to true.
    # +strict_integer+::
    #   Integer literals are not allowed to include commas ',' if set to true.
    #   Such literals will be parsed as String objects.
    #   For Ruby 3.1, this option is ignored.
    # +value_class+::
    #   Specify a class wrapping parsed objects. By default, YPS::Value is used.
    #
    # See also Psych.safe_load[https://docs.ruby-lang.org/en/master/Psych.html#method-c-safe_load].
    def safe_load( # rubocop:disable Metrics/ParameterLists
      yaml,
      permitted_classes: [], permitted_symbols: [], aliases: false,
      filename: nil, fallback: nil, symbolize_names: false, freeze: false,
      strict_integer: false, value_class: Value
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
          Visitors::ToRuby.new(scanner, class_loader, value_class, symbolize_names:, freeze:)
        else
          Visitors::NoAliasRuby.new(scanner, class_loader, value_class, symbolize_names:, freeze:)
        end

      visitor.accept(result)
    end

    ##
    # Similar to +YPS.safe_load+, but Symbol is allowed to be loaded by default.
    #
    # See also Psych.load[https://docs.ruby-lang.org/en/master/Psych.html#method-c-load].
    def load(yaml, permitted_classes: [Symbol], **kwargs)
      safe_load(yaml, permitted_classes:, **kwargs)
    end

    ##
    # Similar to +YPS.safe_load+, but the YAML string is read from the file specified by the +filename+ argument.
    #
    # See also YPS.safe_load
    def safe_load_file(filename, **kwargs)
      File.open(filename, 'r:bom|utf-8') do |f|
        safe_load(f, filename:, **kwargs)
      end
    end

    ##
    # Similar to +YPS.load+, but the YAML string is read from the file specified by the +filename+ argument.
    #
    # See also YPS.load
    def load_file(filename, **kwargs)
      File.open(filename, 'r:bom|utf-8') do |f|
        load(f, filename:, **kwargs)
      end
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
