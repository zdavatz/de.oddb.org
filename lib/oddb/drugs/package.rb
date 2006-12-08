#!/usr/bin/env ruby
# Drugs::Package -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Package < Model
      belongs_to :sequence, :active_agents, :atc, :company, :doses,
        :name, :product, :substances
      has_many :parts
      has_many :prices
      is_coded
      def size
        parts.inject(0) { |memo, part| memo + part.size }
      end
      def price(type, country='DE')
        prices.find { |money| money.is_for?(type, country) }
      end
    end
  end
end
