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
  @logger = logger
end
