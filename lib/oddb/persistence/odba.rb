#!/usr/bin/env ruby
# Persistence::ODBA -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/config'
require 'odba'
require 'odba/connection_pool'
require 'odba/drbwrapper'

require 'oddb/persistence/odba/business/company'
require 'oddb/persistence/odba/drugs/atc'
require 'oddb/persistence/odba/drugs/galenic_form'
require 'oddb/persistence/odba/drugs/galenic_group'
require 'oddb/persistence/odba/drugs/package'
require 'oddb/persistence/odba/drugs/product'
require 'oddb/persistence/odba/drugs/substance'
require 'oddb/persistence/odba/drugs/substance_group'
require 'oddb/persistence/odba/drugs/unit'

module ODDB
  module Persistence
    module ODBA
    end
  end
  ODBA.storage.dbi = ODBA::ConnectionPool.new("DBI:pg:#{@config.db_name}",
                                              @config.db_user, @config.db_auth)
  ODBA.cache.setup
end
