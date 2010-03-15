require 'drb'
require 'oddb/config'

module ODDB
  Currency = DRb::DRbObject.new nil, @config.currency_rates
end
