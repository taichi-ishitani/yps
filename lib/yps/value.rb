# frozen_string_literal: true

module YPS
  ##
  # Position is a placeholder retaining position information of a parsed object.
  #
  # Fields:
  # +filename+::
  #   File name of the original YAML file.
  # +line+::
  #   Line number in the original YAML string where a parsed object is started.
  # +column+::
  #   Column number in the original YAML string where a parsed object is started.
  class Position
    def initialize(filename, line, column) # :nodoc:
      @filename = filename
      @line = line
      @column = column
      freeze
    end

    ##
    # Accessor for the filename of the orignal YAML file
    attr_reader :filename

    ##
    # Accessor for the line number where the parsed object is started.
    attr_reader :line

    ##
    # Accessor for the column number where the parsed object is started.
    attr_reader :column

    ##
    # Return a string representing the position information.
    def to_s
      "filename: #{filename || 'unknown'} line #{line} column #{column}"
    end

    ##
    # Equality operator.
    # Check whether or not self and +other+ point the same position.
    def ==(other)
      filename == other.filename && line == other.line && column == other.column
    end
  end

  ##
  # Value is a wrapper class for a parsed object and serves two main functions:
  #
  # 1. As a placeholder and accessor for the position information of
  #    the wrapped object (via the #position method).
  # 2. Forwarding received method calls to the wrapped object.
  class Value < SimpleDelegator
    def initialize(value, position) # :nodoc:
      super(value)
      @position = position
    end

    ##
    # Accessor for the wrapped object
    def value
      __getobj__
    end

    ##
    # Accessor for the position information of the wrapped object
    attr_reader :position
  end
end
