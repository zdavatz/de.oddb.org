#!/usr/bin/env ruby
# Drugs::Atc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Atc < Model
      has_many :ddds, on_delete(:cascade)
      has_many :sequences
      attr_reader :code
      multilingual :name
      def initialize(code)
        @code = code
      end
      def products
        sequences.collect { |sequence| sequence.product }.uniq
      end
      def <=>(other)
        @code <=> other.code
      end
    end
  end
end
