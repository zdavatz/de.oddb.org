#!/usr/bin/env ruby
# Util::Multilingual -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'oddb/util/multilingual'

module ODDB
  module Util
    class Multilingual
      property :canonical, Hash
      property :synonyms, Array
    end
  end
end
