#!/usr/bin/env ruby
# Drugs::Part -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Part < Model
      belongs_to :package
      belongs_to :composition
      ## A partial package can be described as e.g. 
      #  5 Ampoules of 20 ml 
      #  ^------------------ :size     - Numeric
      #    ^---------------- :unit     - Unit (a multilingual)
      #                ^---- :quantity - Dose 
      #  Possibly a multiplication factor (Integer) can be added.
      attr_accessor :unit, :quantity
      attr_reader :size
      def size=(size)
        if(size.to_i == size)
          @size = size.to_i
        else
          @size = size.to_f
        end
      end
    end
  end
end
