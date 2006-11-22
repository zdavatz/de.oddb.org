#!/usr/bin/env ruby
# Drugs::Sequence -- de.oddb.org -- 31.08.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Sequence < Model
      has_many :compositions
      has_many :packages
      belongs_to :product, :atc, :company, :name
      def doses
        compositions.inject([]) { |memo, comp|
          memo.concat(comp.doses)
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
