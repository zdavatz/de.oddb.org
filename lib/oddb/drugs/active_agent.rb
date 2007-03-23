#!/usr/bin/env ruby
# Drugs::ActiveAgent -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'oddb/model'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
    class ActiveAgent < Model
      include Comparable
      attr_accessor :dose, :substance, :chemical_equivalence
      def initialize(substance, dose, unit="mg")
        @substance = substance
        if(dose.is_a?(Dose))
          @dose = dose
        else
          @dose = Dose.new(dose, unit)
        end
      end
      def <=>(other)
        [@substance, @dose] <=> [other.substance, other.dose]
      end
      def ==(other)
        other && ([@substance, @dose] == [other.substance, other.dose] \
          || @chemical_equivalence == other \
          || ((other = other.chemical_equivalence) && self == other)) \
          || false
      end
    end
  end
end
