#!/usr/bin/env ruby
# Business::Invoice -- de.oddb.org -- 23.01.2008 -- hwyss@ywesee.com

require 'oddb/business/invoice'
require 'oddb/persistence/odba/model'

module ODDB
  module Business
    class Invoice < Model
      odba_index :yus_name
      odba_index :id
      serialize :items
    end
  end
end
