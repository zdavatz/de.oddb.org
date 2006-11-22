#!/usr/bin/env ruby
# Drugs::Unit -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

require 'oddb/drugs/unit'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class Unit < Model
      odba_index :name, 'name.all'
    end
  end
end
