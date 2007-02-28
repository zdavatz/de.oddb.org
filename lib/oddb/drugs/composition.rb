#!/usr/bin/env ruby
# Drugs::Composition -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/model'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
    class Composition < Model
      attr_accessor :galenic_form, :equivalence_factor
      has_many :active_agents, on_delete(:cascade)
      has_many :parts
      def active_agent(substance)
        active_agents.find { |agent| agent.substance == substance }
      end
      def doses
        active_agents.collect { |agent| agent.dose }
      end
      def include?(substance, dose, unit=nil)
        unless(dose.is_a?(Drugs::Dose))
          dose = Drugs::Dose.new(dose, unit)
        end
        active_agents.any? { |act|
          act.substance == substance && act.dose == dose
        }
      end
      def substances
        active_agents.collect { |agent| agent.substance }
      end
      def ==(other)
        other.is_a?(Composition) \
          && @galenic_form == other.galenic_form \
          && active_agents.sort == other.active_agents.sort
      end
    end
  end
end
