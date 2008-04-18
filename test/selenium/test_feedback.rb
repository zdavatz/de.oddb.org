#!/usr/bin/env ruby
# Selenium::TestFeedback -- de.oddb.org -- 11.12.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Selenium
class TestFeedback < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    ODDB.config.data_dir = File.expand_path('../../data', File.dirname(__FILE__))
    ODDB.config.var = File.expand_path('var', File.dirname(__FILE__))
    @path = File.join(ODDB.config.var, 'rss', 'de', 'feedback.rss')
    File.delete(@path) if(File.exist? @path)
    super
  end
  def teardown
    Drugs::Package.instances.clear
    super
  end
  def setup_package(pzn='12345')
    product = Drugs::Product.new
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.atc = Drugs::Atc.new('N04BB01')
    sequence.atc.name.de = 'Amantadin'
    ddd = Drugs::Ddd.new('O')
    ddd.dose = Drugs::Dose.new(5, 'mg')
    sequence.atc.add_ddd(ddd)
    sequence.product = product
    composition = Drugs::Composition.new
    composition.equivalence_factor = '44.6'
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = "Amantadin"
    dose = Drugs::Dose.new(100, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    composition.add_active_agent(active_agent)
    package = Drugs::Package.new
    code = Util::Code.new(:festbetragsstufe, 3, 'DE')
    package.add_code(code)
    code = Util::Code.new(:zuzahlungsbefreit, true, 'DE')
    package.add_code(code)
    code = Util::Code.new(:prescription, true, 'DE')
    package.add_code(code)
    code = Util::Code.new(:cid, pzn, 'DE')
    package.add_code(code)
    part = Drugs::Part.new
    part.composition = composition
    part.package = package
    part.size = 5
    unit = Drugs::Unit.new
    unit.name.de = 'Ampullen'
    part.unit = unit
    part.quantity = Drugs::Dose.new(20, 'ml')
    package.name.de = 'Amantadin by Producer'
    package.sequence = sequence
    package.add_price(Util::Money.new(6, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.save
    package
  end
  def test_feedback
    package = setup_package
    open "/de/drugs/feedback/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Feedback | Amantadin by Producer | Open Drug Database", get_title
    assert is_text_present('Feedback zu Amantadin by Producer in der Handelsform: 5 Ampullen à 20 ml')
    assert is_element_present('name')
    assert is_element_present('email')
    assert is_element_present('email_public')
    assert is_element_present('message')
    assert is_element_present('item_good_experience')
    assert is_element_present('item_recommended')
    assert is_element_present('item_good_impression')
    assert is_element_present('item_helps')
    assert is_text_present("Was steht im Bild unten?")
  end
  def test_feedback__errors
    package = setup_package
    open "/de/drugs/feedback/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Feedback | Amantadin by Producer | Open Drug Database", get_title
    assert is_text_present('Feedback zu Amantadin by Producer in der Handelsform: 5 Ampullen à 20 ml')
    assert is_element_present('name')
    assert is_element_present('email')
    assert is_element_present('email_public')
    assert is_element_present('message')
    assert is_element_present('item_good_experience')
    assert is_element_present('item_recommended')
    assert is_element_present('item_good_impression')
    assert is_element_present('item_helps')
    assert is_text_present("Was steht im Bild unten?")
    assert is_element_present("//input[starts-with(@name, 'captcha')]")
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert is_text_present('Ihre Eingabe stimmt nicht mit dem Bild überein. Bitte versuchen Sie es noch einmal.')
    assert is_text_present('Bitte füllen Sie alle Felder aus.')
    assert is_element_present('name')
    assert is_element_present('email')
    assert is_element_present('email_public')
    assert is_element_present('message')
    assert is_element_present('item_good_experience')
    assert is_element_present('item_recommended')
    assert is_element_present('item_good_impression')
    assert is_element_present('item_helps')
    assert is_text_present("Was steht im Bild unten?")
    assert is_element_present("//input[starts-with(@name, 'captcha')]")
  end
  def test_feedback__success
    flexmock(Turing::Challenge).new_instances\
      .should_receive(:valid_answer?).and_return(true)
    package = setup_package
    open "/de/drugs/feedback/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Feedback | Amantadin by Producer | Open Drug Database", get_title
    assert is_text_present('Feedback zu Amantadin by Producer in der Handelsform: 5 Ampullen à 20 ml')
    assert is_element_present('name')
    assert is_element_present('email')
    assert is_element_present('email_public')
    assert is_element_present('message')
    assert is_element_present('item_good_experience')
    assert is_element_present('item_recommended')
    assert is_element_present('item_good_impression')
    assert is_element_present('item_helps')
    assert is_text_present("Was steht im Bild unten?")
    assert is_element_present("//input[starts-with(@name, 'captcha')]")
    type "name", "My Name"
    type "email", "my.email@home.com"
    check "//input[@name='email_public'][@value='1']"
    type "message", "My personal experience"
    check "//input[@name='item_good_experience'][@value='0']"
    check "//input[@name='item_recommended'][@value='1']"
    check "//input[@name='item_good_impression'][@value='0']"
    check "//input[@name='item_helps'][@value='1']"
    type "//input[starts-with(@name, 'captcha')]", "Valid thanks to Flexmock"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert is_text_present("Vielen Dank! Ihr Feedback wurde gespeichert. Sie können jetzt noch Änderungen vornehmen.")
    assert !is_text_present('Ihre Eingabe stimmt nicht mit dem Bild überein. Bitte versuchen Sie es noch einmal.')
    assert !is_text_present('Bitte geben Sie einen Namen an.')
    assert !is_text_present('Bitte geben Sie eine gültige E-Mail-Adresse an.')
    assert is_element_present('name')
    assert is_element_present('email')
    assert is_element_present('email_public')
    assert is_element_present('message')
    assert is_element_present('item_good_experience')
    assert is_element_present('item_recommended')
    assert is_element_present('item_good_impression')
    assert is_element_present('item_helps')
    assert !is_element_present("//input[starts-with(@name, 'captcha')]")
    assert !is_text_present("Was steht im Bild unten?")
    assert is_text_present("Feedback von My Name\nerstellt am:")
    assert is_text_present("My personal experience")
    assert !is_text_present("My personal experience with this Product was ok.")
    type "message", "My personal experience with this Product was ok."
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert is_text_present("Vielen Dank! Ihr Feedback wurde geändert. Sie können noch weitere Änderungen vornehmen.")
    assert is_text_present("My personal experience with this Product was ok.")
    assert File.exist?(@path)
  end
  def test_feedback__search
    setup_package
    open "/de/drugs/feedback/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Feedback | Amantadin by Producer | Open Drug Database", get_title
    type "query", "Amantadin"
    select "dstype", "Preisvergleich"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
  end
  def test_feedback__limited
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/feedback/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Feedback | Amantadin by Producer | Open Drug Database", get_title
    open "/de/drugs/feedback/pzn/12345"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")
  ensure
    ODDB.config.query_limit = 20
  end
end
  end
end
