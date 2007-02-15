#!/usr/bin/env ruby
# Selenium::TestCompare -- de.oddb.org -- 15.02.2007 -- hwyss@ywesee.com


$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Selenium
class TestCompare < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::Package.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
    super
  end
  def setup_package(name, pzn='12345', price=6)
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
    package.add_price(Util::Money.new(price, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.add_code(Util::Code.new(:cid, pzn, 'DE'))
    package.save
    package
  end
  def test_init
    package = setup_package("Amantadin by Producer")
    open "/"
    assert_equal "ODDB | Medikamente | Home", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 get_title
    click 'link=Amantadin by Producer'
    wait_for_page_to_load "30000"

    assert_equal "ODDB | Medikamente | Preisvergleich | Amantadin by Producer", get_title
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('Amantadin 100 mg')
    assert is_text_present('5 Ampullen x 20 ml')
    assert is_text_present('6.00')
    assert is_text_present("In unserer Datenbank wurden leider keine Produkte gefunden, \ndie mit diesem Produkt verglichen werden können.")
  end
  def test_compare
    package1 = setup_package("Amantadin by Producer", '12345', 6)
    package2 = setup_package("By another name", '54321', 3)
    package2.code(:zuzahlungsbefreit).value = false
    flexstub(package1).should_receive(:comparables)\
      .and_return([package2])
    flexstub(package2).should_receive(:comparables)\
      .and_return([package1])
    open "/de/drugs/compare/pzn/12345"
    assert_equal "ODDB | Medikamente | Preisvergleich | Amantadin by Producer", get_title
    assert is_text_present('-50.0%')
    assert_equal 'origin zuzahlungsbefreit', 
                 get_attribute('//tr[2]@class')
    assert_raises(SeleniumCommandError) { get_attribute('//tr[3]@class') }


    click 'link=By another name'
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Preisvergleich | By another name", get_title
    assert is_text_present('+100.0%')
    assert_equal 'origin', 
                 get_attribute('//tr[2]@class')
    assert_equal 'zuzahlungsbefreit', get_attribute('//tr[3]@class')
  end
  def test_sort
    package1 = setup_package("Amantadin by Producer", '12345', 6)
    package2 = setup_package("By another name", '54321', 6)
    package3 = setup_package("Yet another", '11111', 3)
    flexstub(package1).should_receive(:comparables)\
      .and_return([package2, package3])
    open "/de/drugs/compare/pzn/12345"
    assert_equal "ODDB | Medikamente | Preisvergleich | Amantadin by Producer", get_title
    assert_match(/^Yet another/, @selenium.get_text("cid_0"))
    assert_match(/^By another name/, @selenium.get_text("cid_1"))

    click "//a[@name='th_product']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Preisvergleich | Amantadin by Producer", get_title
    assert_match(/^By another name/, @selenium.get_text("cid_0"))
    assert_match(/^Yet another/, @selenium.get_text("cid_1"))
  end
end
  end
end
