#!/usr/bin/env ruby
# Drugs::ActiveAgent -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'oddb/model'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
    class ActiveAgent < Model
      attr_accessor :dose, :substance, :chemical_equivalence
      def initialize(substance, dose, unit="mg")
        @substance = substance
        if(dose.is_a?(Dose))
          @dose = dose
        else
          @dose = Dose.new(dose, unit)
        end
      end
    end
  end
end
