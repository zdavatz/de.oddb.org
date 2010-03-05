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
    'admins'              => [],
    'auth_domain'         => 'org.oddb.de',
    'auth_server'         => 'drbssl://localhost:9997',
    'config'			        => default_config_files,
    'credentials'         => {},
    'currency_rates'      => 'druby://localhost:10999',
    'data_dir'            => File.expand_path('data', oddb_dir),
    'db_name'             => 'oddb',
    'db_user'             => 'oddb',
    'db_auth'             => 'oddb',
    'db_backend'          => :psql,
    'debug_recipients'    => [],
    'dojo_debug'          => false,
    'default_dstype'      => 'compare',
    'export_dir'          => File.expand_path('var/downloads', oddb_dir),
    'export_hour'         => 4,
    'invoice_server'      => 'druby://localhost:12375',
    'pharmacy_percentage' => 3,
    'pharmacy_premium'    => 8.1,
    'http_proxies'        => [],
    'http_server'         => 'http://localhost',
    'log_file'            => STDERR,
    'log_file_export'     => STDERR,
    'log_level'           => 'INFO',
    'log_level_export'    => 'INFO',
    'mail_charset'        => 'utf8',
    'mail_from'           => 'update@oddb.org',
    'mail_invoice_from'   => '"de.ODDB.org" ipn@oddb.org',
    'mail_invoice_smtp'   => 'ipn@oddb.org',
    'oddb_dir'            => oddb_dir,
    'query_limit'         => 5,
    'query_limit_phase'   => 24 * 60 * 60,
    'payment_period'      => 30,
    'paypal_server'       => 'www.paypal.com',
    'paypal_receiver'     => nil,
    'persistence'         => 'odba',
    'prices'              => { 
      'org.oddb.de.download.1'    => {
        'de.oddb.csv'             => 500,
        'de.oddb.yaml'            => 600,
        'fachinfos.de.oddb.yaml'  => 800,
      },
      'org.oddb.de.download.12'   => {
        'de.oddb.csv'             => 2000,
        'de.oddb.yaml'            => 2500,
        'fachinfos.de.oddb.yaml'  => 1400,
      },
      'org.oddb.de.export.csv'  => 0.16,
      'org.oddb.de.view.365'    => 400,
      'org.oddb.de.view.30'     =>  50,
      'org.oddb.de.view.1'      =>   5,
    },
    'remote_databases'    => [],
    'run_exporter'        => true,
    'run_updater'         => true,
    'server_name'         => 'de.oddb.org',
    'server_url'          => 'druby://localhost:11000',
    'server_url_export'   => 'druby://localhost:11001',
    'session_timeout'     => 3600,
    'smtp_from'           => 'update@oddb.org',
    'smtp_server'         => 'localhost',
    'update_hour'         => 2,
    'var'                 => File.expand_path('var', oddb_dir),
    'vat'                 => 19,
  }

  config = RCLConf::RCLConf.new(ARGV, defaults)
  config.load(config.config)
  @config = config
end
