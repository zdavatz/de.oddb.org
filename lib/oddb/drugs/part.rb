#!/usr/bin/env ruby
# Drugs::Part -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

require 'oddb/model'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
    class Part < Model
      belongs_to :package
      belongs_to :composition, delegates(:active_agents)
      ## A partial package can be described as e.g. 
      #  5 Ampoules of 20 ml 
      #  ^------------------ :size     - Numeric
      #    ^---------------- :unit     - Unit (a multilingual)
      #                ^---- :quantity - Dose 
      #  Possibly a multiplication factor (Integer) can be added.
      attr_accessor :unit, :quantity
      attr_reader :size
      def initialize
        super
        @size = 1
      end
      def comparable_size
        (@quantity || Dose.new(1)) * (@size || 1)
      end
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
