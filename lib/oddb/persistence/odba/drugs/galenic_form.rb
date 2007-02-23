#!/usr/bin/env ruby
# Drugs::GalenicForm -- de.oddb.org -- 11.09.2006 -- hwyss@ywesee.com

require 'oddb/drugs/product'
require 'oddb/drugs/galenic_form'
require 'oddb/persistence/odba/model'
require 'oddb/util/code'

module ODDB
  module Drugs
    class GalenicForm < Model
      odba_index :description, 'description.all'
      odba_index :code, :codes, {:type => 'type.to_s', 
        :country => 'country', :value => 'to_s'}, Util::Code
      serialize :codes
    end
  end
end
