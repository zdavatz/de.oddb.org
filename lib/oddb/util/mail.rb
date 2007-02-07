#!/usr/bin/env ruby
# Util::Mail -- de.oddb.org -- 06.02.2007 -- hwyss@ywesee.com

require 'rmail'
require 'net/smtp'
require 'oddb/config'

module ODDB
  module Util
    module Mail
      def Mail.notify_admins(subject, lines)
        config = ODDB.config
        recipients = config.admins
        mpart = RMail::Message.new
        header = mpart.header
        header.to = recipients
        header.from = config.mail_from
        header.subject = subject
        header.date = Time.now
        header.add('Content-Type', 'text/plain', nil, 
                   'charset' => config.mail_charset)
        mpart.body = lines.join("\n")
        smtp = Net::SMTP.new(config.smtp_server)
        smtp.start {
          recipients.each { |recipient|
            smtp.sendmail(mpart.to_s, config.smtp_from, recipient)
          }
        }
      end
    end
  end
end

