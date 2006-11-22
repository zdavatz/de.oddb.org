#!/usr/bin/env ruby
# Drugs::GalenicForm -- de.oddb.org -- 11.09.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class GalenicForm < Model
      is_coded
      multilingual :description
    end
  end
end
