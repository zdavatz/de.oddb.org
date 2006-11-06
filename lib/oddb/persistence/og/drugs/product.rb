#!/usr/bin/env ruby
# Drugs::Product -- de.oddb.org -- 09.08.2006 -- hwyss@ywesee.com

require 'oddb/drugs/product'
require 'oddb/drugs/sequence'

module ODDB
  module Drugs
    class Product < Model
      property :oddb_id
      has_many :sequences, Sequence
    end
  end
end
