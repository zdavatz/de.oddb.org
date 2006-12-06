#!/usr/bin/env ruby
# Drugs::Package -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com

require 'oddb/drugs/package'
require 'oddb/persistence/odba/model'
require 'oddb/persistence/odba/util/code'

module ODDB
  module Drugs
    class Package < Model
      odba_index :code, :codes, {:type => 'type.to_s', 
        :country => 'country', :value => 'to_s'}, Util::Code
      odba_index :atc, 'atc.code'
      odba_index :name, 'name.all'
      odba_index :substance, :substances, 'name.all', Drugs::Substance
    end
  end
end
