#!/usr/bin/env ruby
# Util::Ipn -- de.oddb.org -- 29.01.2008 -- hwyss@ywesee.com

require 'oddb/business/invoice'
require 'oddb/util/mail'
require 'oddb/util/ydim'
require 'oddb/util/yus'

module ODDB
  module Util
module Ipn
  def Ipn.process(notification)
    id = notification.params["invoice"]
    invoice = Business::Invoice.find_by_id(id) or raise "unknown invoice '#{id}'"
    invoice.status = notification.status.to_s.downcase
    if(notification.complete?)
      Ipn.process_invoice(invoice)
    else
      invoice.ipn = notification
    end
    invoice.save
    invoice
  end
  def Ipn.process_invoice(invoice)
    invoice.items.each { |item| Ipn.process_item invoice, item }
    Ydim.inject(invoice, :payment_received => true)
    Mail.notify_invoice(invoice)
  end
  def Ipn.process_item(invoice, item)
    yus_name = invoice.yus_name
    case item.type
    when :download, :export
      time = Time.now + (60 * 60 * 24)
      if item.type == :download
        date = Date.today >> item.quantity
        time = Time.local date.year, date.month, date.day,
                          time.hour, time.min, time.sec
      end
      item.expiry_time = time
      Util::Yus.grant(yus_name, 'login', "#{ODDB.config.auth_domain}.PowerUser")
      Util::Yus.grant(yus_name, 'download',
                      "#{ODDB.config.auth_domain}.#{item.text}",
                      item.expiry_time)
    when :poweruser
      item.expiry_time = Time.now + (60 * 60 * 24 * item.quantity)
      Util::Yus.set_preference(yus_name, 'poweruser_duration', item.quantity)
      Util::Yus.grant(yus_name, 'login', "#{ODDB.config.auth_domain}.PowerUser")
      Util::Yus.grant(yus_name, 'view', ODDB.config.auth_domain, item.expiry_time)
    end
  end
end
  end
end
