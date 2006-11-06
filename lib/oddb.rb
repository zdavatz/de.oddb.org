#!/usr/bin/env ruby
# ODDB -- bbmb.ch -- 27.10.2006 -- hwyss@ywesee.com

module ODDB
  ODDB_VERSION = File.read(File.expand_path('../.git/HEAD', 
                                            File.dirname(__FILE__)))
  class << self
    attr_accessor :auth, :config, :logger, :persistence, :server
  end
end
