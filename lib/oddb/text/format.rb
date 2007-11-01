#!/usr/bin/env ruby
# Text::Format -- de.oddb.org -- 19.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Format
      attr_accessor :start, :end, :values
      VALID_FORMATS = %w{b i sub}
      def initialize(*args)
        @values = (args & VALID_FORMATS).sort
        @start = 0
        @end = -1
      end
      def range
        @start..@end
      end
      def ==(other)
        case other
        when Format
          @values == other.values
        when Array
          @values == (other & VALID_FORMATS).sort
        else
          false
        end
      end
    end
  end
end

