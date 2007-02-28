#!/usr/bin/env ruby
# @config -- de.oddb.org -- 08.09.2006 -- hwyss@ywesee.com

require 'rclconf'
require 'oddb'

module ODDB
  oddb_dir = File.expand_path('..', ENV['DOCUMENT_ROOT'] || './doc')
  default_dir = File.expand_path('etc', oddb_dir)
  default_config_files = [
    File.join(default_dir, 'oddb.yml'),
    '/etc/oddb/oddb.yml',
  ]
  defaults = {
    'admins'            => [],
    'config'			      => default_config_files,
    'currency_rates'    => 'druby://localhost:10999',
    'data_dir'          => File.expand_path('data', oddb_dir),
    'db_name'           => 'oddb',
    'db_user'           => 'oddb',
    'db_auth'           => 'oddb',
    'db_backend'        => :psql,
    'http_server'       => 'http://localhost',
    'log_file'          => STDERR,
    'log_level'         => 'INFO',
    'mail_charset'      => 'utf8',
    'mail_from'         => 'update@oddb.org',
    'oddb_dir'          => oddb_dir,
    'persistence'       => 'odba',
    'remote_databases'  => [],
    'run_updater'       => true,
    'server_url'        => 'druby://localhost:11000',
    'session_timeout'   => 3600,
    'smtp_from'         => 'update@oddb.org',
    'smtp_server'       => 'localhost',
    'update_hour'       => 2,
    'var'               => File.expand_path('var', oddb_dir),
  }

  config = RCLConf::RCLConf.new(ARGV, defaults)
  config.load(config.config)
  @config = config
end
