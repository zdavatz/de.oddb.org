#!/usr/bin/env ruby
# Drugs::Sequence -- de.oddb.org -- 31.08.2006 -- hwyss@ywesee.com

require 'oddb/drugs/product'
require 'oddb/drugs/composition'

module ODDB
  module Drugs
    class Sequence < Model
      property :oddb_id
      belongs_to :product, Product
      has_many :compositions, Composition
    end
  end
end
