#!/usr/bin/env ruby
# Util::Server -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/html/util/session'
require 'oddb/html/util/validator'
require 'sbsm/drbserver'

module ODDB
  module Util
    class Server < SBSM::DRbServer
      ENABLE_ADMIN = true 
	    SESSION = Html::Util::Session
	    VALIDATOR = Html::Util::Validator
    end
  end
end
