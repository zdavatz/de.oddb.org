#!/usr/bin/env ruby
# Drugs::Product -- de.oddb.org -- 07.09.2006 -- hwyss@ywesee.com

require 'oddb/drugs/product'
require 'oddb/persistence/odba/model'
require 'oddb/persistence/odba/util/code'

module ODDB
  module Drugs
    class Product < Model
      odba_index :name, 'name.all'
    end
  end
end
