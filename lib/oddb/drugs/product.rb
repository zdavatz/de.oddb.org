#!/usr/bin/env ruby
# Drugs::Product -- de.oddb.org -- 09.08.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Product < Model
      belongs_to :atc
      belongs_to :company
      has_many :sequences, on_delete(:cascade), delegates(:substances)
      is_coded
      multilingual :name
      def initialize
        @sequences = []
      end
      def packages
        @sequences.inject([]) { |memo, seq|
          memo.concat(seq.packages)
        }
      end
    end
  end
end
