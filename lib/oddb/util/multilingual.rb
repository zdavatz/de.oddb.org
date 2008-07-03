#!/usr/bin/env ruby
# Util::Multilingual -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

module ODDB
  module Util
    module M10lMethods
      include Comparable
      attr_reader :canonical
      attr_reader :synonyms
      def initialize(canonical={})
        @canonical = canonical
      end
      def all
        @canonical.values
      end
      def empty?
        @canonical.empty?
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
        @canonical.values.sort.first.to_s
      end
      def ==(other)
        case other
        when String
          @canonical.values.any? { |val| val == other } \
            || @synonyms.any? { |val| val == other }
        when M10lDocument
          @canonical == other.canonical && @synonyms == other.synonyms
        when M10lMethods
          @canonical == other.canonical
        else
          false
        end
      end
      def <=>(other)
        all.sort <=> other.all.sort
      end
    end
    class Multilingual
      include M10lMethods
      def initialize(canonical={})
        super
        @synonyms = []
      end
      def add_synonym(synonym)
        @synonyms.push(synonym).uniq! && synonym
      end
      def all
        super.concat(@synonyms)
      end
      def merge(other)
        @synonyms.concat(other.all).uniq!
      end
    end
  end
end
