#!/usr/bin/env ruby
# ODDB -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

VERSION = '2.0.0'

module ODDB
  ODDB_VERSION =
    File.read(File.expand_path('../.git/refs/heads/master',
                               File.dirname(__FILE__)))
  class << self
    attr_accessor :auth, :config, :logger, :persistence, :server, :exporter
  end
end
