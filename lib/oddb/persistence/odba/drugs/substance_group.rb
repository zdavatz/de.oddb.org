#!/usr/bin/env ruby
# Drugs::SubstanceGroup -- de.oddb.org -- 13.11.2006 -- hwyss@ywesee.com

require 'oddb/drugs/substance_group'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class SubstanceGroup < Model
      odba_index :name, 'name.all'
    end
  end
end
