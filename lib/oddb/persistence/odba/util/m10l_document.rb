#!/usr/bin/env ruby
# Util::M10lDocument -- de.oddb.org -- 11.03.2008 -- hwyss@ywesee.com

require 'oddb/util/m10l_document'
require 'oddb/persistence/odba/model'

module ODDB
  module Util
    class M10lDocument < Model
      serialize :previous_sources
    end
  end
end
