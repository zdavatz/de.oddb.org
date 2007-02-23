#!/usr/bin/env ruby
# Drugs::Product -- de.oddb.org -- 07.09.2006 -- hwyss@ywesee.com

require 'oddb/drugs/product'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class Product < Model
      odba_index :name, 'name.all'
      serialize :codes
    end
  end
end
