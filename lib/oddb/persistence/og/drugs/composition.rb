#!/usr/bin/env ruby
# Drugs::Composition -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/drugs/composition'
require 'oddb/drugs/sequence'

module ODDB
  module Drugs
    class Composition < Model
      property :oddb_id
      belongs_to :sequence, Sequence
    end
  end
end
