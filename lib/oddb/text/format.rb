#!/usr/bin/env ruby
# Text::Format -- de.oddb.org -- 19.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Format
      attr_accessor :start, :end, :values
      VALID_FORMATS = %w{b i sub}
      def initialize(*args)
        @values = []
        augment *args
        @start = 0
        @end = -1
      end
      def augment(*args)
        @values.concat (args & VALID_FORMATS)
        @values.sort!
        @values.uniq!
        @values
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

