#!/usr/bin/env ruby
# Persistence::ODBA -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/config'
require 'odba/connection_pool'
require 'odba/drbwrapper'

require 'oddb/persistence/odba/util/code'
require 'oddb/persistence/odba/drugs/product'
require 'oddb/persistence/odba/drugs/substance'

module ODDB
  module Persistence
    module ODBA
    end
  end
  ODBA.storage.dbi = ODBA::ConnectionPool.new("DBI:pg:#{@config.db_name}",
                                              @config.db_user, @config.db_auth)
  ODBA.cache.setup
end
