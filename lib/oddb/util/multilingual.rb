#!/usr/bin/env ruby
# Util::Multilingual -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

module ODDB
  module Util
    class Multilingual
      attr_reader :canonical
      attr_reader :synonyms
      def initialize
        @canonical = {}
        @synonyms = []
      end
      def all
        @canonical.values.concat(@synonyms)
      end
      def method_missing(meth, *args, &block)
        case meth.to_s
        when /^[a-z]{2}$/
          @canonical[meth]
        when /^([a-z]{2})=$/
          @canonical.store($~[1].to_sym, args.first)
        else
          super(meth, *args, &block)
        end
      end
      def to_s
        @canonical.values.sort.first
      end
      def ==(other)
        case other
        when String
          @canonical.values.any? { |val| val == other } \
            || @synonyms.any? { |val| val == other }
        when Multilingual
          @canonical == other.canonical && @synonyms == other.synonyms
        else
          false
        end
      end
    end
  end
end
