# frozen_string_literal: true

module YPS
  module NodeExtension
    refine Psych::Nodes::Node do
      attr_accessor :filename

      def mapping_key?
        @mapping_key || false
      end

      def mapping_key
        @mapping_key = true
      end
    end
  end
end
