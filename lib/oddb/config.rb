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
    'admins'                => [],
    'auth_domain'           => 'org.oddb.de',
    'auth_server'           => 'drbssl://localhost:9997',
    'config'			          => default_config_files,
    'country'               => 'DE',
    'credentials'           => {},
    'currency_rates'        => 'druby://localhost:10999',
    'data_dir'              => File.expand_path('data', oddb_dir),
    'db_name'               => 'oddb',
    'db_user'               => 'oddb',
    'db_auth'               => 'oddb',
    'db_backend'            => :psql,
    'debug_recipients'      => [],
    'dojo_debug'            => false,
    'download_log_dir'      => File.expand_path('log/download', oddb_dir),
    'download_uncompressed' => [
      'compendium_de.oddb.org.firefox.epub',
      'compendium_de.oddb.org.htc.prc',
      'compendium_de.oddb.org.kindle.mobi',
      'compendium_de.oddb.org.stanza.epub',
      'patinfos_de.oddb.org.firefox.epub',
      'patinfos_de.oddb.org.htc.prc',
      'patinfos_de.oddb.org.kindle.mobi',
      'patinfos_de.oddb.org.stanza.epub',
    ],
    'default_dstype'        => 'compare',
    'export_dir'            => File.expand_path('var/downloads', oddb_dir),
    'export_hour'           => 4,
    'invoice_server'        => 'druby://localhost:12375',
    'pharmacy_percentage'   => 3,
    'pharmacy_premium'      => 8.1,
    'http_proxies'          => [],
    'http_server'           => 'http://localhost',
    'log_file'              => STDERR,
    'log_file_export'       => STDERR,
    'log_level'             => 'INFO',
    'log_level_export'      => 'INFO',
    'mail_charset'          => 'utf8',
    'mail_from'             => 'update@oddb.org',
    'mail_invoice_from'     => '"de.ODDB.org" ipn@oddb.org',
    'mail_invoice_smtp'     => 'ipn@oddb.org',
    'oddb_dir'              => oddb_dir,
    'query_limit'           => 5,
    'query_limit_phase'     => 24 * 60 * 60,
    'payment_period'        => 30,
    'paypal_server'         => 'www.paypal.com',
    'paypal_receiver'       => nil,
    'persistence'           => 'odba',
    'prices'                => { 
      'org.oddb.de.download.1'    => {
        'compendium_de.oddb.org.firefox.epub' => 17,
        'compendium_de.oddb.org.htc.prc'      => 17,
        'compendium_de.oddb.org.kindle.mobi'  => 17,
        'compendium_de.oddb.org.stanza.epub'  => 17,
        'chde.xls'                            => 600,
        'de.oddb.csv'                         => 500,
        'de.oddb.yaml'                        => 600,
        'fachinfos.de.oddb.yaml'              => 800,
        'patinfos.de.oddb.yaml'               => 800,
        'patinfos_de.oddb.org.firefox.epub'   => 17,
        'patinfos_de.oddb.org.htc.prc'        => 17,
        'patinfos_de.oddb.org.kindle.mobi'    => 17,
        'patinfos_de.oddb.org.stanza.epub'    => 17,
      },
      'org.oddb.de.download.12'   => {
        'chde.xls'                => 2000,
        'de.oddb.csv'             => 2000,
        'de.oddb.yaml'            => 2500,
        'fachinfos.de.oddb.yaml'  => 1400,
        'patinfos.de.oddb.yaml'   => 1400,
      },
      'org.oddb.de.export.csv'  => 0.16,
      'org.oddb.de.view.365'    => 400,
      'org.oddb.de.view.30'     =>  50,
      'org.oddb.de.view.1'      =>   5,
    },
    'remote_databases'      => [],
    'run_exporter'          => true,
    'run_updater'           => true,
    'server_name'           => 'de.oddb.org',
    'server_url'            => 'druby://localhost:11000',
    'server_url_export'     => 'druby://localhost:11001',
    'session_timeout'       => 3600,
    'smtp_authtype'         => :plain,
    'smtp_domain'           => 'oddb.org',
    'smtp_pass'             => nil,
    'smtp_port'             => 587,
    'smtp_server'           => 'localhost',
    'smtp_user'             => 'update@oddb.org',
    'update_hour'           => 2,
    'var'                   => File.expand_path('var', oddb_dir),
    'vat'                   => 19,
  }

  config = RCLConf::RCLConf.new(ARGV, defaults)
  config.load(config.config)
  @config = config
end
