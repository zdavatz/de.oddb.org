#!/usr/bin/env ruby
# Util::Code -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

require 'oddb/util/code'

module ODDB
  module Util
    class Code
      puts "#{self}.include(ODBA::Persistable)"
      include ODBA::Persistable
    end
  end
end
