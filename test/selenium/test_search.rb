#!/usr/bin/env ruby
# Selenium::TestSearch -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com


$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Selenium
class TestSearch < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::Package.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
    super
  end
  def test_init
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    assert @selenium.is_element_present("query")
    assert @selenium.is_element_present("reset")
    assert @selenium.is_element_present("//input[@name='search']")
    assert_match Regexp.new(ODDB.config.http_server), 
      @selenium.get_attribute("//form[@name='search']@action")
  end
  def setup_package(name="Amantadin by Producer")
    product = Drugs::Product.new
    product.atc = Drugs::Atc.new('N04BB01')
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.product = product
    composition = Drugs::Composition.new
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = 'Amantadin'
    dose = Drugs::Dose.new(100, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    composition.add_active_agent(active_agent)
    package = Drugs::Package.new
    code = Util::Code.new(:festbetragsstufe, 3, 'DE')
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
    product.name.de = name
    package.sequence = sequence
    package.add_price(Util::Money.new(6, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.save
    package
  end
  def test_search
    package = setup_package
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    @selenium.type "query", "Amantadin"
    @selenium.click "//input[@type='submit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert @selenium.is_text_present('100 mg')
    assert @selenium.is_text_present('5 Ampullen x 20 ml')
    assert @selenium.is_text_present('6.00')
    assert @selenium.is_text_present('10.00')
    assert @selenium.is_text_present('-4.00')
    assert @selenium.is_text_present('3')
    assert @selenium.is_text_present('Ja')
    assert @selenium.is_text_present('N04BB01')
    assert @selenium.is_text_present('Producer AG')

    ## State::Drugs::Result does not re-search if the query is the same
    package2 = Drugs::Package.new
    package2.sequence = package.sequence
    package2.save
    package2.add_price(Util::Money.new(999999, :public, 'DE'))
    @selenium.open('/de/drugs/search/query/Amantadin')
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert !@selenium.is_text_present('999999.00')

    ## Sort result
    @selenium.click "//a[@name='th_atc']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title

    @selenium.click "//a[@name='th_atc']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title

    @selenium.click "//a[@name='th_code_zuzahlungsbefreit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title

    @selenium.click "//a[@name='th_code_festbetragsstufe']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title

    @selenium.click "//a[@name='th_price_difference']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title

    ## an empty Result:
    @selenium.type "query", "Gabapentin"
    @selenium.click "//input[@type='submit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Gabapentin", 
                 @selenium.get_title
    expected = <<-EOS
Ihr Such-Stichwort hat zu keinem Suchergebnis geführt. Bitte
überprüfen Sie die Schreibweise und versuchen Sie es noch
einmal.
    EOS
    assert @selenium.is_text_present(expected)
  end
  def test_search__details
    package = setup_package
    package.add_code(Util::Code.new(:cid, '12345', 'DE'))
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    @selenium.type "query", "Amantadin"
    @selenium.click "//input[@type='submit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')

    ## click through to Details
    @selenium.click "link=Amantadin 100 mg"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Details | 12345", 
                 @selenium.get_title

    ## click back to Result
    @selenium.click "link=Suchresultat"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
  end
  def test_search__multiple_substances
    package = setup_package
    substance = Drugs::Substance.new
    substance.name.de = "Propranolol"
    dose = Drugs::Dose.new(50, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    package.sequence.compositions.first.add_active_agent(active_agent)
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    @selenium.type "query", "Amantadin"
    @selenium.click "//input[@type='submit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert @selenium.is_text_present('2 Wirkstoffe')
  end
  def test_search__short
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    @selenium.type "query", "A"
    @selenium.click "//input[@type='submit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | A", 
                 @selenium.get_title
    expected = 'Ihr Such-Stichwort ergibt ein sehr grosses Resultat. Bitte verwenden Sie mindestens 3 Buchstaben.'
    assert @selenium.is_text_present(expected)
  end
  def test_search__company
    setup_package
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    @selenium.type "query", "Producer"
    @selenium.click "//input[@type='submit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Producer", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert @selenium.is_text_present('100 mg')
    assert @selenium.is_text_present('5 Ampullen x 20 ml')
    assert @selenium.is_text_present('6.00')
    assert @selenium.is_text_present('10.00')
    assert @selenium.is_text_present('-4.00')
    assert @selenium.is_text_present('3')
    assert @selenium.is_text_present('Ja')
    assert @selenium.is_text_present('N04BB01')
    assert @selenium.is_text_present('Producer AG')
  end
  def test_search__direct_sort
    setup_package("Amonamon")
    setup_package("Nomamonamon")
    @selenium.open "/de/drugs/search/query/Producer/sortvalue/product"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Producer", 
                 @selenium.get_title

    assert_match(/^Nomamonamon/, @selenium.get_text("cid_0"))
    assert_match(/^Amonamon/, @selenium.get_text("cid_1"))
  end
end
  end
end
