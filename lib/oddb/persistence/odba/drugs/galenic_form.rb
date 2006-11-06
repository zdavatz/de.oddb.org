#!/usr/bin/env ruby
# Drugs::GalenicForm -- de.oddb.org -- 11.09.2006 -- hwyss@ywesee.com

require 'oddb/drugs/product'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class GalenicForm < Model
      odba_index :description, 'description.all'
    end
  end
end
