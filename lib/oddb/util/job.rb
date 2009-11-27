require 'drb'
require 'oddb/config'
require 'oddb/drugs'
require 'oddb/persistence'
require 'oddb/util'
require 'encoding/character/utf-8'

module ODDB
  module Util
module Job
  def Job.run &block
    system = DRb::DRbObject.new(nil, ODDB.config.server_url)
    DRb.start_service
    begin
      system.peer_cache ODBA.cache
      block.call
    ensure
      system.unpeer_cache ODBA.cache
    end
  end
end
  end
end
