#!/usr/bin/env ruby
# Util::TestIpn -- de.oddb.org -- 01.02.2008 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))
$: << File.expand_path('..', File.dirname(__FILE__))

require 'flexmock'
require 'oddb/util/ipn'
require 'stub/model'
require 'test/unit'

module ODDB
  module Util
class TestIpn < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    Drugs::Package.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
    super
  end
  def test_process__incomplete
    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    invoice.save

    note = flexmock('notification')
    note.should_receive(:params).and_return({"invoice" => invoice.id})
    note.should_receive(:status).and_return('Error')
    note.should_receive(:complete?).and_return false
    flexmock(invoice).should_receive(:save)
    Ipn.process(note)
    assert_equal(note, invoice.ipn)
  end
  def test_process
    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    invoice.save

    note = flexmock('notification')
    note.should_receive(:params).and_return({"invoice" => invoice.id})
    note.should_receive(:status).and_return('Completed')
    note.should_receive(:complete?).and_return true

    flexmock(Ydim).should_receive(:inject)\
      .with(invoice, {:payment_received => true})
    flexmock(Mail).should_receive(:notify_invoice).with(invoice)
    ODDB.config.auth_domain = 'org.oddb.de'
    yus = flexmock(Util::Yus)
    yus.should_receive(:set_preference)\
      .with(email, 'poweruser_duration', 365)
    yus.should_receive(:grant).with(email, 'login', 'org.oddb.de.PowerUser')
    yus.should_receive(:grant).and_return { |yus_name, action, area, time| 
      assert_equal email, yus_name
      assert_equal 'view', action
      assert_equal 'org.oddb.de', area
      day = Time.now + (60 * 60 * 24 * 365)
      assert_equal day.year, time.year
      assert_equal day.month, time.month
      assert_equal day.day, time.day, 'test always fails around midnight'
    }
    flexmock(invoice).should_receive(:save)
    Ipn.process(note)
    assert_equal('completed', invoice.status)
  end
  def test_process_invoice
    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    flexmock(Ydim).should_receive(:inject)\
      .with(invoice, {:payment_received => true})
    flexmock(Mail).should_receive(:notify_invoice).with(invoice)
    ODDB.config.auth_domain = 'org.oddb.de'
    yus = flexmock(Util::Yus)
    yus.should_receive(:set_preference)\
      .with(email, 'poweruser_duration', 365)
    yus.should_receive(:grant).with(email, 'login', 'org.oddb.de.PowerUser')
    yus.should_receive(:grant).and_return { |yus_name, action, area, time| 
      assert_equal email, yus_name
      assert_equal 'view', action
      assert_equal 'org.oddb.de', area
      day = Time.now + (60 * 60 * 24 * 365)
      assert_equal day.year, time.year
      assert_equal day.month, time.month
      assert_equal day.day, time.day, 'test always fails around midnight'
    }
    Ipn.process_invoice(invoice)
  end
  def test_process_item__poweruser
    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    ODDB.config.auth_domain = 'org.oddb.de'
    yus = flexmock(Util::Yus)
    yus.should_receive(:set_preference)\
      .with(email, 'poweruser_duration', 365)
    yus.should_receive(:grant).with(email, 'login', 'org.oddb.de.PowerUser')
    yus.should_receive(:grant).and_return { |yus_name, action, area, time| 
      assert_equal email, yus_name
      assert_equal 'view', action
      assert_equal 'org.oddb.de', area
      day = Time.now + (60 * 60 * 24 * 365)
      assert_equal day.year, time.year
      assert_equal day.month, time.month
      assert_equal day.day, time.day, 'test always fails around midnight'
    }
    Ipn.process_item(invoice, item)
  end
end
  end
end
