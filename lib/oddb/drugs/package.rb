#!/usr/bin/env ruby
# Drugs::Package -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Package < Model
      belongs_to :sequence, 
        delegates(:active_agents, :atc, :company, :doses,
                  :galenic_forms, :name, :product, :substances)
      has_many :parts, on_delete(:cascade), delegates(:comparable_size)
      has_many :prices
      is_coded
      def comparable?(other)
        return false unless(other.is_a?(Package))
        csizes = comparable_size.collect { |psize|
          (psize*0.75)..(psize*1.25)
        }
        osizes = other.comparable_size
        idx = -1
        osizes.length == csizes.length && csizes.all? { |range|
          idx += 1
          range.include?(osizes.at(idx))
        }
      end
      def comparables
        @sequence.comparables.inject([]) { |memo, sequence|
          memo.concat sequence.packages.select { |package|
            (package != self) && comparable?(package)
          }
        }
      end
      def price(type, country='DE')
        prices.find { |money| money.is_for?(type, country) }
      end
      def size
        parts.inject(0) { |memo, part| memo + part.size }
      end
    end
  end
end
