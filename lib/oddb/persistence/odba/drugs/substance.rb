#!/usr/bin/env ruby
# Drugs::Substance -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

require 'oddb/drugs/substance'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class Substance < Model
      odba_index :name, 'name.all'
      odba_index :code, :codes, {:type => 'type.to_s', :country => 'country', 
        :value => 'to_s'}, Util::Code
    end
  end
end
