#!/usr/bin/env ruby
# Selenium::Collect -- de.oddb.org -- 04.02.2008 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'

module ODDB
  module Selenium
class TestCollect < Test::Unit::TestCase
  include Selenium::TestCase
  def test_collect__unknown_invoice
    open "/de/drugs/collect/invoice/875967c31e83eec9decea52130e7ee72"
    assert is_text_present('Fehler')
    assert is_text_present('Ihre Transaktion ist bei uns nicht registriert. Setzen Sie sich bitte per E-Mail mit uns in Verbindung.')
  end
  def test_collect__unpaid_invoice
    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    invoice.save
    id = invoice.id

    open "/de/drugs/collect/invoice/#{id}"
    assert is_text_present('Ihre Bezahlung ist von PayPal noch nicht bestätigt worden. Sobald dies geschieht werden wir Sie per E-Mail benachrichtigen.')
    ## automatic reload
    wait_for_page_to_load "30000"
    assert is_text_present('Ihre Bezahlung ist von PayPal noch nicht bestätigt worden. Sobald dies geschieht werden wir Sie per E-Mail benachrichtigen.')
  end
  def test_collect
    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    invoice.status = 'completed'
    invoice.save
    id = invoice.id

    open "/de/drugs/collect/invoice/#{id}"
    assert is_text_present('Vielen Dank! Als angemeldeter Benutzer können Sie jetzt ohne Beschränkung Abfragen vornehmen.')
    assert is_text_present('Ihr PowerUser-Account ist bereit. Bitte melden Sie sich hier erneut mit E-Mail und Passwort an.')

    click 'link=hier'
    wait_for_page_to_load "30000"
    assert is_element_present("email")
    assert is_element_present("pass")
  end
  def test_collect__logged_in
    ODDB.config.auth_domain = 'org.oddb.de'

    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    invoice.status = 'completed'
    invoice.save
    id = invoice.id

    permissions = [
      ['login', 'org.oddb.de.PowerUser'], ['view', 'org.oddb.de']
    ]
    login email, *permissions

    open "/de/drugs/collect/invoice/#{id}"
    assert is_text_present('Vielen Dank! Als angemeldeter Benutzer können Sie jetzt ohne Beschränkung Abfragen vornehmen.')
    assert is_text_present('Sie sind bereits angemeldet und können sofort weitersuchen.')
  end
  def test_collect__redirect
    ODDB.config.auth_domain = 'org.oddb.de'
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")

    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    invoice.status = 'completed'
    invoice.save
    id = invoice.id

    permissions = [
      ['login', 'org.oddb.de.PowerUser'], ['view', 'org.oddb.de']
    ]
    login email, *permissions

    open "/de/drugs/collect/invoice/#{id}"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
  ensure
    ODDB.config.query_limit = 20
  end
  def test_collect__redirect__later
    ODDB.config.auth_domain = 'org.oddb.de'
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")

    email = 'test@invoice.ch'
    invoice = Business::Invoice.new
    invoice.yus_name = email
    item = invoice.add :poweruser, "unlimited access", 365, "Tage", 2
    invoice.save
    id = invoice.id

    user = login email, ['login', 'org.oddb.de.PowerUser']

    open "/de/drugs/collect/invoice/#{id}"
    assert is_text_present('Ihre Bezahlung ist von PayPal noch nicht bestätigt worden. Sobald dies geschieht werden wir Sie per E-Mail benachrichtigen.')

    invoice.status = 'completed'
    user.permissions.push ['view', 'org.oddb.de']

    ## automatic reload
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
  ensure
    ODDB.config.query_limit = 20
  end
end
  end
end
