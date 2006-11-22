#!/usr/bin/env ruby
# Util::Code -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

require 'date'

module ODDB
  module Util
    class Code
      attr_accessor :type, :value, :country, :format
      def initialize(type, value, country, valid_from=Date.today)
        @values = { valid_from => value}
        @type, @country = type.to_s.downcase, country.to_s.upcase
      end
      def hash
        [@type, @value, @country].hash
      end
      def is_for?(type, country)
        @type == type.to_s.downcase && @country == country.to_s.upcase
      end
      def format
        @format || case @type
        when 'registration'
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
        format % value
      end
      def value(date=Date.today)
        pair = @values.sort.reverse.find { |valid_from, value|
          valid_from <= date
        }
        pair && pair.last
      end
      def value=(value_and_date)
        value, valid_from = nil
        if(value_and_date.is_a?(Array))
          value, valid_from = value_and_date
        else
          value = value_and_date
          valid_from = Date.today
        end
        if(value(valid_from) != value)
          @values.store(valid_from, value)
        end
      end
      def ==(other)
        if(other.is_a?(Code))
          other.type == @type && other.value == value \
            && other.country == @country
        elsif(other.is_a?(Hash))
          res = other[:type].to_s.downcase == @type \
            && other[:value] == value \
            && other[:country] == @country
        else
          false
        end
      end
      alias :eql? :==
    end
  end
end
