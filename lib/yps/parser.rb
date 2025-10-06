# frozen_string_literal: true

module YPS # :nodoc: all
  using NodeExtension

  class Handler < Psych::Handlers::DocumentStream
    attr_accessor :filename

    def scalar(...)
      node = super

      # The given value was added to @last.children as a mappking key inside super.
      # Therefore, it is a mappking key if size of @last.children is odd.
      if @last.mapping? && @last.children.size.odd?
        node.mapping_key
      end

      node
    end

    def set_start_location(node) # rubocop:disable Naming/AccessorMethodName
      super
      node.filename = filename
    end
  end

  class Parser < Psych::Parser
    def self.parse(yaml, filename, &)
      new(&).parse(yaml, filename)
    end

    def initialize(&)
      super(Handler.new(&))
    end

    def parse(yaml, filename)
      @handler.filename = filename
      super
    end
  end
end
