#!/usr/bin/env ruby
# Drugs::GalenicGroup -- de.oddb.org -- 21.02.2007 -- hwyss@ywesee.com

require 'oddb/drugs/galenic_group'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class GalenicGroup < Model
      odba_index :name, 'name.all'
    end
  end
end
