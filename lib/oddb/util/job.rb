require 'drb'
require 'oddb/config'
require 'oddb/drugs'
require 'oddb/persistence'
require 'oddb/util'
require 'encoding/character/utf-8'

module ODDB
  module Util
module Job
  def Job.run opts={}, &block
    system = DRb::DRbObject.new(nil, ODDB.config.server_url)
    DRb.start_service
    begin
      system.peer_cache ODBA.cache unless opts[:readonly]
      block.call
    ensure
      system.unpeer_cache ODBA.cache unless opts[:readonly]
    end
  end
end
  end
end
