require 'logger'
require 'oddb/config'

module ODDB
  log_file = @config.log_file
  if(log_file.is_a?(String))
    FileUtils.mkdir_p(File.dirname(log_file))
    log_file = File.open(log_file, 'a')
    log_file.sync = true
  end
  logger = Logger.new(log_file)
  logger.level = Logger.const_get(@config.log_level)
  ## The PayPal Gem depends on ActiveSupport, which foolishly redefines the
  #  Logger.default_formatter. That's why we need to explicitly set
  #  logger.formatter to the standard Formatter here:
  logger.formatter = Logger::Formatter.new
  @logger = logger
  require 'pp'
end
