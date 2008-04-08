#!/usr/bin/env ruby
# Selenium::TestPackage -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'
require 'oddb/import/pharmnet'

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
  def test_package
    package = setup_package
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    assert is_text_present('Amantadin by Producer - Producer AG')
    assert is_text_present('12345')
    assert !is_text_present('54321')
    assert is_text_present('N04BB01 ( Amantadin )')
    assert is_text_present('Packungsgrösse und Wirkstoffe')
    assert is_text_present('5 Ampullen x 20 ml')
    assert is_text_present('100 mg')
    assert is_text_present('Ja')
    assert !is_text_present('Nein')
    package.code(:zuzahlungsbefreit).value = false
    refresh
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    assert_equal "Nein", get_text('//tr[5]/td[2]')
    assert_equal "Ja", get_text('//tr[6]/td[2]')

    package2 = setup_package('54321')
    open "/de/drugs/package/pzn/54321"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer - Producer AG')
    assert is_text_present('Ja')
    assert !is_text_present('Nein')
    assert is_text_present('54321')
    assert !is_text_present('12345')
  end
  def test_package__search
    setup_package
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    type "query", "Amantadin"
    select "dstype", "Preisvergleich"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
  end
  def test_package__limited
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    open "/de/drugs/package/pzn/12345"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")
  ensure
    ODDB.config.query_limit = 20
  end
  def test_admin_package
    package = setup_package
    user = login_admin
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    assert is_element_present("name")
    assert is_element_present("code_cid")
    assert is_element_present("price_public")
    assert is_element_present("price_festbetrag")
    assert is_element_present("code_festbetragsstufe")
    assert is_element_present("code_festbetragsgruppe")
    assert is_element_present("code_zuzahlungsbefreit")
    assert is_element_present("code_prescription")
=begin
    assert is_element_present("fi_url")
    fachinfo = "A Fachinfo-Document"
    type "fi_url", "http://host.domain/path.rtf"
    flexmock(Import::PharmNet::Import).new_instances\
      .should_receive(:import_rtf).and_return { fachinfo }
    click "//input[@name='update']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    assert is_text_present("FI")
    assert_equal(fachinfo, package.sequence.fachinfo.de)
=end
  end
  def test_admin_package__not_limited
    ODDB.config.query_limit = 1
    package = setup_package
    user = login_admin
    2.times {
      open "/de/drugs/package/pzn/12345"
      assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
      assert is_element_present("name")
      assert is_element_present("code_cid")
      assert is_element_present("price_public")
      assert is_element_present("price_festbetrag")
      assert is_element_present("code_festbetragsstufe")
      assert is_element_present("code_festbetragsgruppe")
      assert is_element_present("code_zuzahlungsbefreit")
      assert is_element_present("code_prescription")
    }
  ensure
    ODDB.config.query_limit = 20
  end
end
  end
end
