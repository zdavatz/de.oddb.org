#!/usr/bin/env ruby
# Selenium::TestInit -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com


$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Business
    class Company
      simulate_database(:name)
    end
  end
  module Drugs
    class Atc < Model
      simulate_database
    end
    class Package < Model
      simulate_database(:name)
    end
    class Product < Model
      simulate_database 
    end
    class Sequence < Model
      simulate_database 
    end
  end
  module Selenium
class TestInit < Test::Unit::TestCase
  include Selenium::TestCase
  def test_init
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    assert @selenium.is_element_present("query")
    assert @selenium.is_element_present("reset")
    assert @selenium.is_element_present("//input[@name='search']")
    assert_match Regexp.new(ODDB.config.http_server), 
      @selenium.get_attribute("//form[@name='search']@action")
  end
  def test_search
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
    substance.name.de = "Amantadin"
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
    unit = Drugs::Unit.new
    unit.name.de = 'Ampullen'
    part.unit = unit
    part.quantity = Drugs::Dose.new(20, 'ml')
    product.name.de = 'Amantadin by Producer'
    package.sequence = sequence
    package.add_price(Util::Money.new(6, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.save
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
    package2.sequence = sequence
    package2.save
    package2.add_price(Util::Money.new(999999, :public, 'DE'))
    @selenium.open('/de/drugs/search/query/Amantadin')
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert !@selenium.is_text_present('999999.00')

    ## Sort ATC-Class
    @selenium.click "//a[@name='th_atc']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
    @selenium.click "//a[@name='th_zuzahlungsbefreit']"
    @selenium.wait_for_page_to_load "30000"
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
end
  end
end
