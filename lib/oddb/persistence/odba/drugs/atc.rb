#!/usr/bin/env ruby
# Drugs::Atc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'oddb/drugs/atc'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class Atc < Model
      odba_index :code
      odba_index :level, :code
      odba_index :name, 'name.all'
    end
  end
end
