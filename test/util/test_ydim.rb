#!/usr/bin/env ruby
# Util::TestYdim -- de.oddb.org -- 04.02.2008 -- hwyss@ywesee.com


$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/business/invoice'
require 'oddb/util/ydim'

module ODDB
  module Util
class TestYdim < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @client = flexmock('ydim-client')
    @ydim = flexmock(YDIM::Client).new_instances
    @ydim.should_receive(:login)
    @drb_ydim = DRb.start_service('druby://localhost:0', @ydim)
    YDIM::Client::CONFIG.server_url = @drb_ydim.uri
    @yus = flexmock(Util::Yus)
    super
  end
  def teardown
    @drb_ydim.stop_service
    super
  end
  def setup_ydim_invoice(unique_id, description)
    invoice = flexmock('ydim-invoice')
    invoice.should_receive(:description=).with(description)
    invoice.should_receive(:date=).with(Date.today)
    invoice.should_receive(:currency=).with('EUR')
    invoice.should_receive(:payment_period=).with(30)
    invoice.should_receive(:unique_id).and_return unique_id
    invoice.should_receive(:payment_received=).with(true)
    invoice.should_receive(:save).times(1)
    invoice
  end
  def test_inject__old_invoice
    invoice = Business::Invoice.new
    invoice.ydim_id = 123
    invoice.yus_name = 'test@invoice.com'
    invoice.add(:poweruser, "unlimited access", 365, "Tage", 2)
    ydim_inv = flexmock('remote invoice')
    @ydim.should_receive(:invoice).with(123).and_return ydim_inv
    assert_equal ydim_inv, Ydim.inject(invoice)
  end
  def test_inject__new_invoice
    invoice = Business::Invoice.new
    invoice.yus_name = 'test@invoice.com'
    item = invoice.add(:poweruser, "unlimited access", 365, "Tage", 2)
    item.expiry_time = exp = Time.now + 365 * 24 * 60 * 60

    @yus.should_receive(:get_preference).with('test@invoice.com', :ydim_id)\
      .and_return 158
    @yus.should_receive(:set_preference).with('test@invoice.com', :ydim_id, 158)

    today = Date.today
    next_year = (today >> 12) - 1
    descr = "PowerUser de.oddb.org #{today.strftime("%d.%m.%Y")} - #{next_year.strftime("%d.%m.%Y")}"
    puts descr
    ydim_inv = setup_ydim_invoice(1234, descr)
    @ydim.should_receive(:create_invoice).with(158).and_return {  ydim_inv }
    expected = [
      { :unit => "Tage", :text => "unlimited access", 
        :expiry_time => exp, :quantity => 365, :price => 2.0, 
        :time => item.time } ]
    @ydim.should_receive(:add_items).with(1234, expected)
    
    assert_equal ydim_inv, Ydim.inject(invoice, :payment_received => true)
  end
  def test_debitor_id__old_customer_by_id
    @yus.should_receive(:get_preference).with('test@invoice.com', :ydim_id)\
      .and_return 158
    assert_equal(158, Ydim.debitor_id('test@invoice.com'))
  end
  def test_debitor_id__old_customer_by_email
    @yus.should_receive(:get_preference).with('test@invoice.com', :ydim_id)\
      .and_return nil
    debitor = flexmock('debitor')
    debitor.should_receive(:unique_id).and_return(158)
    @ydim.should_receive(:search_debitors).with('test@invoice.com')\
      .and_return { [debitor] }
    assert_equal(158, Ydim.debitor_id('test@invoice.com'))
  end
  def test_debitor_id__new_customer
    @yus.should_receive(:get_preference).with('test@invoice.com', :ydim_id)\
      .and_return nil
    debitor = flexmock('debitor')
    debitor.should_receive(:unique_id).and_return(158)
    @ydim.should_receive(:search_debitors).with('test@invoice.com')\
      .and_return { [] }
    ydim_debitor = flexmock('ydim-debitor')
    keys = [ :salutation, :name_last, :name_first ]
    @yus.should_receive(:get_preferences).with('test@invoice.com', keys)\
      .and_return { 
        { :salutation => 'salutation_m', 
          :name_last => 'Test', 
          :name_first => 'Fred',
        } 
    }
    @ydim.should_receive(:create_debitor).and_return(ydim_debitor)
    ydim_debitor.should_receive(:salutation=).with('Herr')
    ydim_debitor.should_receive(:contact_firstname=).with('Fred')
    ydim_debitor.should_receive(:contact=).with('Test')
    ydim_debitor.should_receive(:debitor_type=).with('dt_info')
    ydim_debitor.should_receive(:email=).with('test@invoice.com')
    ydim_debitor.should_receive(:save)
    ydim_debitor.should_receive(:unique_id).and_return 158

    assert_equal(158, Ydim.debitor_id('test@invoice.com'))
  end
end
  end
end
