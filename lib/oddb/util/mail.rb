#!/usr/bin/env ruby
# Util::Mail -- de.oddb.org -- 06.02.2007 -- hwyss@ywesee.com

require 'rmail'
require 'net/smtp'
require 'oddb/config'
require 'oddb/html/util/lookandfeel'
require 'oddb/util/yus'

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
        sendmail(mpart, config.smtp_from, recipients)
      end
      def Mail.notify_invoice(invoice)
        config = ODDB.config
        lnf = Html::Util::LookandfeelStub.new('de')
        mpart = RMail::Message.new
        header = mpart.header
        header.to = recipient = invoice.yus_name
        header.from = config.mail_invoice_from
        header.subject = lnf.lookup(:poweruser_mail_subject)
        header.date = Time.now
        header.add('Content-Type', 'text/plain', nil, 
                   'charset' => config.mail_charset)
        recipients = [recipient].concat config.debug_recipients
        yus = Util::Yus.get_preferences(recipient, :salutation, :name_last)
        parts = [
          lnf.lookup(:poweruser_mail_salut, lnf.lookup(yus[:salutation]), 
                     yus[:name_last]),
        ]
        instructed = false
        invoice.items.each { |item|
          case item.type
          when :download
            unless instructed
              parts.push lnf.lookup(:download_mail_body)
              parts.push lnf.lookup(:download_mail_instr)
            end
            instructed = true
            parts.push lnf._event_url(:collect, [:invoice, invoice.id,
                                                 :file, item.text])
          when :export
            parts.push lnf.lookup(:download_export_mail_body)
            parts.push lnf.lookup(:download_export_mail_instr)
            parts.push lnf._event_url(:collect, [:invoice, invoice.id])
          when :poweruser
            days = item.quantity
            duration = (days == 1) \
                     ? lnf.lookup(:days_one_genitive) \
                     : lnf.lookup(:days_genitive, days)
            parts.push lnf.lookup(:poweruser_mail_body)
            parts.push lnf.lookup(:poweruser_mail_instr,
                                  duration, lnf._event_url(:login))
          end
        }
        mpart.body = parts.join("\n\n")
        sendmail(mpart, config.mail_invoice_smtp, recipients)
      end
      def Mail.sendmail(mpart, from, recipients)
        smtp = Net::SMTP.new(ODDB.config.smtp_server)
        smtp.start {
          recipients.each { |recipient|
            smtp.sendmail(mpart.to_s, from, recipient)
          }
        }
      end
    end
  end
end
