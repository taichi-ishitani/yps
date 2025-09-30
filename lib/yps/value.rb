# frozen_string_literal: true

module YPS
  Position = Struct.new(:filename, :line, :column) do
    def self.create(filename, start_line, start_column)
      new(filename, start_line + 1, start_column + 1).freeze
    end

    def to_s
      "filename: #{filename || 'unknown'} line #{line} column #{column}"
    end
  end

  class Value < SimpleDelegator
    def initialize(value, position)
      super(value)
      @position = position
    end

    alias_method :value, :__getobj__
    attr_reader :position
  end
end
