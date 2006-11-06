#!/usr/bin/env ruby
# Drugs::Sequence -- de.oddb.org -- 31.08.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Sequence < Model
      multilingual :name
    end
  end
end
