#!/usr/bin/env ruby
# Drugs::Sequence -- de.oddb.org -- 08.01.2008 -- hwyss@ywesee.com

require 'oddb/drugs/sequence'
require 'oddb/persistence/odba/model'
require 'oddb/text/document'

module ODDB
  module Drugs
    class Sequence < Model
      odba_index :code, :codes, {:type => 'type.to_s', :country => 'country', 
        :value => 'to_s'}, Util::Code
      odba_index :fachinfo_indications_de, 'fachinfo.de',
                 'chapter("indications").to_s', Text::Document,
                 :fulltext => true, :dictionary => 'german'
      odba_index :product, :product, 'name.all', Drugs::Product,
        :resolve_target => :sequences
      serialize :codes
    end
  end
end
