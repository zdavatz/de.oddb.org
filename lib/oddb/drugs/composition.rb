#!/usr/bin/env ruby
# Drugs::Composition -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Composition < Model
      multilingual :name
    end
  end
end
