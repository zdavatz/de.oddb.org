#!/usr/bin/env ruby
# ODDB -- de.oddb.org -- 13.02.2011 -- zdavatz@ywesee.com

VERSION = '2.0.1'

module ODDB
  ODDB_VERSION =
    File.read(File.expand_path('../.git/refs/heads/master',
                               File.dirname(__FILE__)))
  class << self
    attr_accessor :auth, :config, :logger, :persistence, :server, :exporter
  end
end
