#!/usr/bin/env ruby
# Util::TestMail -- de.oddb.org -- 06.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/business/invoice'
require 'oddb/util/mail'
require 'flexmock'

module ODDB
  module Util
class TestMail < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @config = ODDB.config
    @config.mail_invoice_from = "IPN <ipn@oddb.org>"
    @config.mail_invoice_smtp = "ipn@oddb.org"
  end
  def test_notify_admins
    @config.admins = ['admin1@ywesee.com', 'admin2@ywesee.com']
    smtp = flexmock('SMTP')
    flexstub(Net::SMTP).should_receive(:new).with('localhost')\
      .times(1).and_return(smtp)
    smtp.should_receive(:start).times(1).and_return { |blk|
      smtp.should_receive(:sendmail)\
        .with(String, 'update@oddb.org', 'admin1@ywesee.com')\
        .times(1).and_return { assert(true) }
      smtp.should_receive(:sendmail)\
        .with(String, 'update@oddb.org', 'admin2@ywesee.com')\
        .times(1).and_return { assert(true) }
      blk.call
    }
    Mail.notify_admins('Test-Mail', 
                       [ "This test-mail was sent from",
                         sprintf("%s:%s", __FILE__, __LINE__),
                         "TestMail#test_notify_admins"])
  end
  def test_notify_invoice
    invoice = Business::Invoice.new
    invoice.yus_name = 'test@invoice.com'
    invoice.add(:poweruser, "unlimited access", 365, "Tage", 2)
    yus = flexmock(Util::Yus)
    yus.should_receive(:get_preferences)\
      .with('test@invoice.com', :salutation, :name_last).and_return {
      { :salutation => "salutation_m", :name_last => "Tester" }
    }
    @config.debug_recipients = [
    'admin1@ywesee.com', 'admin2@ywesee.com']
    expected = <<-EOS
To: test@invoice.com
From: IPN <ipn@oddb.org>
Subject: Power-User bei ODDB.org
Content-Type: text/plain; charset=utf8

Guten Tag Herr Tester

Die Bezahlung für Ihren Power-User-Account konnte erfolgreich abgewickelt werden.

Um während 365 Tagen uneingeschränkt Abfragen tätigen zu können, melden sie sich bitte unter http://de.oddb.org/de/drugs/login/ an.
    EOS
    smtp = flexmock('SMTP')
    flexstub(Net::SMTP).should_receive(:new).with('localhost')\
      .times(1).and_return(smtp)
    smtp.should_receive(:start).times(1).and_return { |blk|
      smtp.should_receive(:sendmail)\
        .with(String, 'ipn@oddb.org', 'test@invoice.com')\
        .times(1).and_return { |body, _, _|
        assert_match(/^Date: (Mon|Tue|Wed|Thu|Fri|Sat|Sun)/, body)
        body.sub!(/^Date:.*$\n/, '')
        assert_equal expected, body
       }
      smtp.should_receive(:sendmail)\
        .with(String, 'ipn@oddb.org', 'admin1@ywesee.com')\
        .times(1).and_return { assert(true) }
      smtp.should_receive(:sendmail)\
        .with(String, 'ipn@oddb.org', 'admin2@ywesee.com')\
        .times(1).and_return { assert(true) }
      blk.call
    }
    Mail.notify_invoice(invoice)
  end
end
  end
end
