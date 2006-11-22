#!/usr/bin/env ruby
# Drugs::SubstanceGroup -- de.oddb.org -- 13.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class SubstanceGroup < Model
      multilingual :name
      has_many :substances
    end
  end
end
