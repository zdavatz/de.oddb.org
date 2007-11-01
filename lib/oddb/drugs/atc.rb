#!/usr/bin/env ruby
# Drugs::Atc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Atc < Model
      has_many :ddds, on_delete(:cascade)
      has_many :sequences, delegates(:packages)
      attr_reader :code
      multilingual :name
      multilingual :guidelines
      multilingual :ddd_guidelines
      def initialize(code)
        @code = code
      end
      def interesting?
        !(ddds.empty? && guidelines.empty? && ddd_guidelines.empty?)
      end
      def level
        case len = @code.length
        when 7
          5
        when 1
          len
        else
          len - 1
        end
      end
      def parent
        Atc.find_by_code(parent_code)
      end
      def parent_code
        case level
        when 2
          @code[0,1]
        when 3..5
          @code[0,level]
        end
      end
      def products
        sequences.collect { |sequence| sequence.product }.uniq
      end
      def to_s
        @code.to_s
      end
      def <=>(other)
        @code <=> other.code
      end
    end
  end
end
