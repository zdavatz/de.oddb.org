#!/usr/bin/env ruby
# Util::Code -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

module ODDB
  module Util
    class Code
      attr_accessor :type, :value, :country, :format
      def initialize(type, value, country)
        @type, @value, @country = type, value, country.to_s.upcase
      end
      def ==(other)
        other.is_a?(Code) && other.type == @type && other.value == @value \
          && other.country == @country
      end
      alias :eql? :==
      def hash
        [@type, @value, @country].hash
      end
      def format
        @format || case @type
        when :registration
          case @country
          when 'CH'
            "%05i"
          else
            "%s"
          end
        else "%s"
        end
      end
      def to_s
        format % @value
      end
    end
  end
end
