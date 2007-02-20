#!/usr/bin/env ruby
# Drugs::Sequence -- de.oddb.org -- 31.08.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Sequence < Model
      belongs_to :atc
      belongs_to :product, delegates(:company, :name)
      has_many :compositions, 
        delegates(:active_agents, :doses, :galenic_form, :substances),
        on_delete(:cascade)
      has_many :packages, on_delete(:cascade)
      def comparable?(other)
        other.is_a?(Sequence) && compositions == other.compositions
      end
      def comparables
        atc.sequences.select { |sequence|
          comparable?(sequence)
        }
      end
      def include?(substance, dose=nil, unit=nil)
        compositions.any? { |comp|
          comp.include?(substance, dose, unit)
        }
      end
    end
  end
end
