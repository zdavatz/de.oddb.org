#!/usr/bin/env ruby
# Selenium::TestInit -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com


$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Selenium
class TestPackage < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
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
  def test_package
    package = setup_package
    @selenium.open "/de/drugs/package/pzn/12345"
    assert_equal "ODDB | Medikamente | Details | Amantadin by Producer", @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer - Producer AG')
    assert @selenium.is_text_present('12345')
    assert !@selenium.is_text_present('54321')
    assert @selenium.is_text_present('N04BB01 ( Amantadin )')
    assert @selenium.is_text_present('Packungsgrösse und Wirkstoffe')
    assert @selenium.is_text_present('5 Ampullen x 20 ml')
    assert @selenium.is_text_present('100 mg')
    assert @selenium.is_text_present('Ja')
    assert !@selenium.is_text_present('Nein')
    package.code(:zuzahlungsbefreit).value = false
    @selenium.refresh
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Details | Amantadin by Producer", @selenium.get_title
    assert !@selenium.is_text_present('Ja')
    assert @selenium.is_text_present('Nein')

    package2 = setup_package('54321')
    @selenium.open "/de/drugs/package/pzn/54321"
    assert_equal "ODDB | Medikamente | Details | Amantadin by Producer", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer - Producer AG')
    assert @selenium.is_text_present('Ja')
    assert !@selenium.is_text_present('Nein')
    assert @selenium.is_text_present('54321')
    assert !@selenium.is_text_present('12345')
  end
  def test_package__search
    setup_package
    @selenium.open "/de/drugs/package/pzn/12345"
    assert_equal "ODDB | Medikamente | Details | Amantadin by Producer", @selenium.get_title
    @selenium.type "query", "Amantadin"
    @selenium.click "//input[@type='submit']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title
  end
end
  end
end
