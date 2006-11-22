#!/usr/bin/env ruby
# Business::Company -- de.oddb.org -- 22.11.2006 -- hwyss@ywesee.com

require 'oddb/business/company'
require 'oddb/persistence/odba/model'

module ODDB
  module Business
    class Company < Model
      odba_index :name, 'name.all'
    end
  end
end
