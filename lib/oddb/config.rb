#!/usr/bin/env ruby
# @config -- de.oddb.org -- 08.09.2006 -- hwyss@ywesee.com

require 'rclconf'
require 'oddb'

module ODDB
  default_dir = File.expand_path('../etc', ENV['DOCUMENT_ROOT'])
  default_config_files = [
    File.join(default_dir, 'oddb.yml'),
    '/etc/oddb/oddb.yml',
  ]
  defaults = {
    'config'			      => default_config_files,
    'db_name'           => 'oddb',
    'db_user'           => 'oddb',
    'db_auth'           => 'oddb',
    'db_backend'        => :psql,
    'http_server'       => 'http://localhost',
    'log_file'          => STDERR,
    'log_level'         => 'INFO',
    'persistence'       => 'odba',
    'server_url'        => 'druby://localhost:11000',
    'session_timeout'   => 3600,
    'oddb_dir'          => File.expand_path('..', default_dir),
    'data_dir'          => File.expand_path('../data', default_dir),
  }

  config = RCLConf::RCLConf.new(ARGV, defaults)
  config.load(config.config)
  @config = config
end
