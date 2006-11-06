#!/usr/bin/env ruby
# Drugs::Product -- de.oddb.org -- 09.08.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Product < Model
      multilingual :name
      attr_reader :sequences
      def initialize
        @sequences = []
      end
    end
  end
end
