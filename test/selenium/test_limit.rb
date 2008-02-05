#!/usr/bin/env ruby
# Selenium::TestLimit -- de.oddb.org -- 01.02.2008 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'odba'
require 'oddb/drugs'
require 'oddb/util'
require 'stub/model'

module ODDB
  module Selenium
class TestLimit < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::Package.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
    @cache = flexstub(ODBA.cache)
    flexstub(Currency).should_receive(:rate)\
      .with('EUR', 'CHF').and_return(1.5)
    currency = flexmock('Currency')
    @currency = DRb.start_service('druby://localhost:0', currency)
    ODDB.config.currency_rates = @currency.uri
    currency.should_receive(:rate).with('EUR', 'CHF').and_return(1.6)
    super
  end
  def setup_autosession(yus)
    session = flexmock('session')
    yus.should_receive(:autosession).and_return {  |domain, block|
      assert_equal 'org.oddb.de', domain
      block.call session
    }
    session
  end
  def setup_package(name="Amantadin by Producer", atccode='N04BB01')
    product = Drugs::Product.new
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.product = product
    atc = Drugs::Atc.new(atccode)
    atc.name.de = 'Amantadin'
    ddd = Drugs::Ddd.new('O')
    ddd.dose = Drugs::Dose.new(10, 'mg')
    atc.add_ddd(ddd)
    sequence.atc = atc
    composition = Drugs::Composition.new
    galform = Drugs::GalenicForm.new
    galform.description.de = 'Tabletten'
    composition.galenic_form = galform
    grp = Drugs::GalenicGroup.new('Tabletten')
    grp.administration = 'O'
    galform.group = grp
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = 'Amantadin'
    dose = Drugs::Dose.new(100, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    composition.add_active_agent(active_agent)
    package = Drugs::Package.new
    code = Util::Code.new(:cid, '12345', 'DE')
    package.add_code(code)
    code = Util::Code.new(:festbetragsstufe, 3, 'DE')
    package.add_code(code)
    code = Util::Code.new(:festbetragsgruppe, 4, 'DE')
    package.add_code(code)
    code = Util::Code.new(:zuzahlungsbefreit, true, 'DE')
    package.add_code(code)
    part = Drugs::Part.new
    part.package = package
    part.size = 5
    part.composition = composition
    unit = Drugs::Unit.new
    unit.name.de = 'Ampullen'
    part.unit = unit
    part.quantity = Drugs::Dose.new(20, 'ml')
    package.name.de = name
    package.sequence = sequence
    package.add_price(Util::Money.new(6, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.save
    package
  end
  def test_limit
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    2.times {
      open "/de/drugs/search/query/Amantadin"
      assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                   get_title
      assert is_text_present("Abfragebeschränkung")
    }
  ensure
    ODDB.config.query_limit = 20
  end
  def test_limit__login__fail_unknown_user
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")
    @auth.should_receive(:login).and_return { raise Yus::UnknownEntityError }
    type "email", "unknown@bbmb.ch"
    type "pass", "secret"
    click "//input[@name='login_']"
    wait_for_page_to_load "30000"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert_equal "error", get_attribute("//label[@for='email']@class")
  ensure
    ODDB.config.query_limit = 20
  end
  def test_limit__login__fail_wrong_password
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")
    @auth.should_receive(:login).and_return { raise Yus::AuthenticationError }
    type "email", "unknown@bbmb.ch"
    type "pass", "secret"
    click "//input[@name='login_']"
    wait_for_page_to_load "30000"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert_equal "error", get_attribute("//label[@for='pass']@class")
  ensure
    ODDB.config.query_limit = 20
  end
  def test_limit__login
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")

    email = "poweruser@oddb.org"
    permissions = [
      ['login', 'org.oddb.de.PowerUser'], ['view', 'org.oddb.de']
    ]
    user = mock_user email, *permissions
    @auth.should_receive(:login).and_return(user)
    type "email", email
    type "pass", "sikrit"
    click "//input[@name='login_']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
  ensure
    ODDB.config.query_limit = 20
  end
  def test_limit__new_user__error
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")

    click "//input[@type='submit']"
    wait_for_page_to_load "30000"

    assert is_text_present("Bitte wählen Sie eine Zeitdauer")
  ensure
    ODDB.config.query_limit = 20
  end
  def test_limit__new_user
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")

    click "//input[@name='days']"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    
    assert is_text_present("Power-User Datenerfassung")
    assert is_text_present('Bitte geben Sie Ihre persönlichen Angaben ein und wählen Sie einen Benutzernamen und ein Passwort.')

    assert_equal "E-Mail", get_text("//label[@for='email']")
    assert is_element_present("email")
    assert_equal "Passwort", get_text("//label[@for='pass']")
    assert is_element_present("pass")
    assert_equal "Bestätigung", get_text("//label[@for='confirm_pass']")
    assert is_element_present("confirm_pass")
    assert_equal "Anrede", get_text("//label[@for='salutation']")
    assert is_element_present("salutation")
    assert_equal "Nachname", get_text("//label[@for='name_last']")
    assert is_element_present("name_last")
    assert_equal "Vorname", get_text("//label[@for='name_first']")
    assert is_element_present("name_first")

    assert is_text_present("365 x")
    assert is_text_present("unlimited access")
  ensure
    ODDB.config.query_limit = 20
  end
  def test_limit__new_user__step2_error
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")

    click "//input[@name='days']"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    
    assert is_text_present("Power-User Datenerfassung")
    assert is_text_present('Bitte geben Sie Ihre persönlichen Angaben ein und wählen Sie einen Benutzernamen und ein Passwort.')

    @auth.should_receive(:login).and_return { raise Yus::UnknownEntityError }
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert is_text_present("Bitte füllen Sie alle Felder aus.")
    %w{email pass confirm_pass salutation name_last name_first}.each { |key|
      assert_equal "error", get_attribute("//label[@for='#{key}']@class")
    }
  ensure
    ODDB.config.query_limit = 20
  end
  def test_limit__new_user__step2
    yus = flexmock("yus-server")
    remote = DRb.start_service('druby://localhost:0', yus)
    yus_session = setup_autosession(yus)
    yus_session.should_receive(:get_entity_preferences).and_return({})
    email = "poweruser@oddb.org"
    ODDB.config.auth_server = remote.uri
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")

    click "//input[@name='days']"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    
    assert is_text_present("Power-User Datenerfassung")
    assert is_text_present('Bitte geben Sie Ihre persönlichen Angaben ein und wählen Sie einen Benutzernamen und ein Passwort.')

    @auth.should_receive(:login).and_return { raise Yus::UnknownEntityError }
    type "email", email
    type "pass", "secret"
    type "confirm_pass", "secret"
    select "//select[@name='salutation']", "Herr"
    type "name_last", "Test"
    type "name_first", "Fritz"

    yus_session.should_receive(:create_entity).with(email, "5ebe2294ecd0e0f08eab7690d2a6ee69")
    permissions = [
      ['login', 'org.oddb.de.PowerUser'], ['view', 'org.oddb.de']
    ]
    user = mock_user email, *permissions
    ODDB.server = server = flexmock("server")
    server.should_receive(:login).and_return(user)
    @auth.should_receive(:login).and_return(user)

    click "//input[@type='submit']"
    wait_for_page_to_load "30000"

    output = @http_server.redirected_output 
    assert_match /www.sandbox.paypal.com/, output
  ensure
    ODDB.config.query_limit = 20
  end
end
  end
end
