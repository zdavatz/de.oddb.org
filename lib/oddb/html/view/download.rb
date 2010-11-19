require 'htmlgrid/passthru'
require 'fileutils'

module ODDB
  module Html
    module View
class Download < HtmlGrid::PassThru
  def to_html(context)
    if download_file = @session.user_input(:file) and email = @session.user_input(:email)
      # Logging a file download 
      # Normally it is saved in log/download directory
      time = Time.now
      log_dir = File.join(ODDB.config.download_log_dir, time.year.to_s)
      FileUtils.mkdir_p log_dir
      log_file = File.join(log_dir, time.month.to_s + '.log')
      Logger.new(log_file).info do 
        [
          time.strftime('%Y-%m-%d %H:%M:%S %Z'),
          @session.remote_addr,
          email,
          File.join(ODDB.config.export_dir, download_file)
        ].join(';')
      end
    end
 
    @session.passthru(@model)
    ''
  end
end
    end
  end
end

