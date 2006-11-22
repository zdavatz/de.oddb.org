#!/usr/bin/env ruby
# Drugs::Unit -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Unit < Model
      multilingual :name
    end
  end
end
