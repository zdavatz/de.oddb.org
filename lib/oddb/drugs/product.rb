#!/usr/bin/env ruby
# Drugs::Product -- de.oddb.org -- 09.08.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Product < Model
      belongs_to :company
      has_many :sequences, on_delete(:cascade), delegates(:substances)
      multilingual :name
      def initialize
        @sequences = []
      end
      def atcs
        sequences.collect { |sequence| sequence.atc }.compact.uniq
      end
      def packages
        @sequences.inject([]) { |memo, seq|
          memo.concat(seq.packages)
        }
      end
    end
  end
end
