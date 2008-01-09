#!/usr/bin/env ruby
# Drugs::Sequence -- de.oddb.org -- 08.01.2008 -- hwyss@ywesee.com

require 'oddb/drugs/sequence'
require 'oddb/persistence/odba/model'

module ODDB
  module Drugs
    class Sequence < Model
      odba_index :code, :codes, {:type => 'type.to_s', :country => 'country', 
        :value => 'to_s'}, Util::Code
      serialize :codes
    end
  end
end
