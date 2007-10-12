#!/usr/bin/env ruby
# Util::Exporter -- de.oddb.org -- 02.10.2007 -- hwyss@ywesee.com

require 'drb'

module ODDB
  @exporter = DRb::DRbObject.new(nil, @config.server_url_export)
end
