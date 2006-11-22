#!/usr/bin/env ruby
# Model -- de.oddb.org -- 07.09.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  class Model
    include ODBA::Persistable
    def save
      odba_isolated_store
      self.class.connectors.each { |conn|
        self.send(conn).odba_store
      }
    end
    class << self
      alias :all :odba_extent
    end
  end
end
