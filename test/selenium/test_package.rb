#!/usr/bin/env ruby
# Selenium::TestPackage -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com

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
    Drugs::Part.instances.clear
    Drugs::Package.instances.clear
    Drugs::ActiveAgent.instances.clear
    Drugs::Composition.instances.clear
    Drugs::Sequence.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
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
    assert is_text_present('5 Ampullen à 20 ml')
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
end
class TestAdminPackage < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::Part.instances.clear
    Drugs::Package.instances.clear
    Drugs::ActiveAgent.instances.clear
    Drugs::Composition.instances.clear
    Drugs::Sequence.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
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
    assert is_element_present("sequence")
    assert is_element_present("code_prescription")
    assert is_element_present("update")
    assert is_element_present("delete")

    assert_equal "Amantadin by Producer", get_value("name")
    assert_equal "12345", get_value("code_cid")
    assert_equal "6.00", get_value("price_public")
    assert_equal "10.00", get_value("price_festbetrag")
    assert_equal "3", get_value("code_festbetragsstufe")
    assert_equal "", get_value("code_festbetragsgruppe")
    assert is_checked("code_zuzahlungsbefreit")
    assert is_checked("code_prescription")
    assert_equal "Amantadin 100 mg", 
                 get_selected_label("//select[@name='sequence']")

    assert !is_element_present("link=-")
    assert is_element_present("multi[0]")
    assert is_element_present("size[0]")
    assert is_element_present("unit[0]")
    assert is_element_present("quantity[0]")
    assert is_element_present("composition[0]")
    assert is_element_present("link=+")

    assert_equal "5", get_value("size[0]")
    assert_equal "Ampullen", get_value("unit[0]")
    assert_equal "20 ml", get_value("quantity[0]")
    assert_equal "Amantadin 100 mg", 
                 get_selected_label("//select[@name='composition[0]']")
  end
  def test_admin_package__update__error
    package = setup_package
    other = setup_package('54321')
    user = login_admin
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title

    type "name", ""
    type "code_cid", "54321"
    type "price_public", ""
    type "price_festbetrag", ""
    type "code_festbetragsstufe", ""
    type "code_festbetragsgruppe", ""
    #assert is_element_present("sequence")
    click "code_prescription"
    click "update"

    wait_for_page_to_load "30000"

    assert is_text_present("Bitte geben Sie einen Namen an.")
    assert is_text_present("Die Pharmazentralnummer '54321' (Amantadin by Producer) ist bereits vergeben.")
    assert_equal "Amantadin by Producer", get_value("name")
    assert_equal "12345", get_value("code_cid")
    assert_equal "", get_value("price_public")
    assert_equal "", get_value("price_festbetrag")
    assert_equal "", get_value("code_festbetragsstufe")
    assert_equal "", get_value("code_festbetragsgruppe")
    assert is_checked("code_zuzahlungsbefreit")
    assert !is_checked("code_prescription")
    #assert_equal "Amantadin 100 mg", 
    #             get_selected_label("//select[@name='sequence']")
    
    assert_equal "Amantadin by Producer", package.name.de
    assert_equal '12345', package.code(:cid).value
    assert_equal nil, package.price(:public)
    assert_equal nil, package.price(:festbetrag)
    assert_equal nil, package.code(:festbetragsstufe).value
    assert_equal nil, package.code(:festbetragsgruppe).value
    assert_equal true, package.code(:zuzahlungsbefreit).value
    assert_equal false, package.code(:prescription).value
  end
  def test_admin_package__update__success
    package = setup_package
    user = login_admin
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title

    type "name", "Modified Name"
    type "code_cid", "54321"
    type "price_public", "12"
    type "price_festbetrag", "9"
    type "code_festbetragsstufe", "1"
    type "code_festbetragsgruppe", "2"
    click "code_zuzahlungsbefreit"
    #assert is_element_present("sequence")
    click "code_prescription"
    click "update"

    wait_for_page_to_load "30000"

    assert_equal "Modified Name", get_value("name")
    assert_equal "54321", get_value("code_cid")
    assert_equal "12.00", get_value("price_public")
    assert_equal "9.00", get_value("price_festbetrag")
    assert_equal "1", get_value("code_festbetragsstufe")
    assert_equal "2", get_value("code_festbetragsgruppe")
    assert !is_checked("code_zuzahlungsbefreit")
    assert !is_checked("code_prescription")
    #assert_equal "Amantadin 100 mg", 
    #             get_selected_label("//select[@name='sequence']")
    
    assert_equal "Modified Name", package.name.de
    assert_equal '54321', package.code(:cid).value
    assert_equal 12, package.price(:public)
    assert_equal 9, package.price(:festbetrag)
    assert_equal "1", package.code(:festbetragsstufe).value
    assert_equal "2", package.code(:festbetragsgruppe).value
    assert_equal false, package.code(:zuzahlungsbefreit).value
    assert_equal false, package.code(:prescription).value
  end
  def test_admin_package__delete
    package = setup_package
    user = login_admin
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title

    click "link=Sequenz"
    wait_for_page_to_load "30000"
    link_loc = "link=12345"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{package.sequence.uid} | Open Drug Database", get_title
    assert is_element_present(link_loc)
    click link_loc
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title

    click "delete"
    assert_equal "Wollen Sie diese Packung wirklich löschen?", get_confirmation

    wait_for_page_to_load "30000"

    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{package.sequence.uid} | Open Drug Database", get_title
    assert !is_element_present(link_loc)
  end
  def test_admin_package__parts
    package = setup_package
    unit = ODDB::Drugs::Unit.new
    unit.name.de = "Fertigspritzen"
    unit.save
    user = login_admin
    open "/de/drugs/package/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    assert is_element_present("link=+")
    assert !is_element_present("link=-")

    click "link=+"
    sleep(0.5)
    assert !is_element_present("link=+")
    assert is_element_present("link=-")
    assert is_element_present("multi[1]")
    assert is_element_present("size[1]")
    assert is_element_present("unit[1]")
    assert is_element_present("quantity[1]")
    assert is_element_present("composition[1]")
    refresh
    wait_for_page_to_load "30000"

    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", get_title
    assert is_element_present("link=+")
    assert !is_element_present("link=-")
    assert !is_element_present("multi[1]")
    assert !is_element_present("size[1]")
    assert !is_element_present("unit[1]")
    assert !is_element_present("quantity[1]")
    assert !is_element_present("composition[1]")

    click "link=+"
    sleep(0.5)
    type "multi[1]", "10"
    type "size[1]", "5"
    type "unit[1]", "Fertigspritzen"
    type "quantity[1]", "20ml"

    click "update"
    wait_for_page_to_load "30000"

    assert_equal 2, package.parts.size
    part = package.parts.last
    assert_equal 10, part.multi
    assert_equal 5, part.size
    assert_equal unit, part.unit
    assert_equal ODDB::Drugs::Dose.new(20, 'ml'), part.quantity

    assert is_element_present("link=+")
    assert is_element_present("link=-")
    assert is_element_present("multi[1]")
    assert is_element_present("size[1]")
    assert is_element_present("unit[1]")
    assert is_element_present("quantity[1]")
    assert is_element_present("composition[1]")
    assert_equal "10", get_value("multi[1]")
    assert_equal "5", get_value("size[1]")
    assert_equal "Fertigspritzen", get_value("unit[1]")
    assert_equal "20 ml", get_value("quantity[1]")

    click "link=+"
    sleep(0.5)
    assert is_element_present("multi[2]")
    click "//table[@id='parts']//tr[3]//td[1]//a"
    sleep(0.5)
    assert is_element_present("link=+")
    assert !is_element_present("multi[2]")
 
    click "//table[@id='parts']//tr[2]//td[1]//a"
    sleep(0.5)
    assert !is_element_present("multi[1]")
    assert_equal 1, package.parts.size
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
  def test_admin_new_package__success
    package = setup_package
    user = login_admin
    uid = package.sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    click "new_package"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Neue Packung | Open Drug Database", get_title

    type "name", "New Package"
    type "code_cid", "12346"
    type "price_public", "12"
    type "price_festbetrag", "9"
    type "code_festbetragsstufe", "1"
    type "code_festbetragsgruppe", "2"
    click "code_zuzahlungsbefreit"
    #assert is_element_present("sequence")
    click "code_prescription"
    click "update"

    wait_for_page_to_load "30000"

    assert_equal "New Package", get_value("name")
    assert_equal "12346", get_value("code_cid")
    assert_equal "12.00", get_value("price_public")
    assert_equal "9.00", get_value("price_festbetrag")
    assert_equal "1", get_value("code_festbetragsstufe")
    assert_equal "2", get_value("code_festbetragsgruppe")
    assert is_checked("code_zuzahlungsbefreit")
    assert is_checked("code_prescription")
    
    assert_equal 2, package.sequence.packages.size
    package = package.sequence.packages.last
    assert_equal "New Package", package.name.de
    assert_equal '12346', package.code(:cid).value
    assert_equal 12, package.price(:public)
    assert_equal 9, package.price(:festbetrag)
    assert_equal "1", package.code(:festbetragsstufe).value
    assert_equal "2", package.code(:festbetragsgruppe).value
    assert_equal true, package.code(:zuzahlungsbefreit).value
    assert_equal true, package.code(:prescription).value
  end
  def test_admin_new_package__errors
    package = setup_package
    user = login_admin
    uid = package.sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    click "new_package"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Neue Packung | Open Drug Database", get_title

    type "code_cid", "12345"
    type "price_public", "12"
    type "price_festbetrag", "9"
    type "code_festbetragsstufe", "1"
    type "code_festbetragsgruppe", "2"
    click "code_zuzahlungsbefreit"
    #assert is_element_present("sequence")
    click "code_prescription"
    click "update"

    wait_for_page_to_load "30000"

    assert is_text_present("Bitte geben Sie einen Namen an.")
    assert is_text_present("Die Pharmazentralnummer '12345' (Amantadin by Producer) ist bereits vergeben.")
    assert_equal "12345", get_value("code_cid")
    assert_equal "12", get_value("price_public")
    assert_equal "9", get_value("price_festbetrag")
    assert_equal "1", get_value("code_festbetragsstufe")
    assert_equal "2", get_value("code_festbetragsgruppe")
    assert !is_checked("code_zuzahlungsbefreit")
    assert !is_checked("code_prescription")
    
    assert_equal 1, package.sequence.packages.size
  end
  def test_admin_new_package__delete
    package = setup_package
    user = login_admin
    uid = package.sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    click "new_package"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Neue Packung | Open Drug Database", get_title

    click "delete"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    assert_equal 1, package.sequence.packages.size
  end
end
  end
end
