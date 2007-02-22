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
  def setup_package(name="Amantadin by Producer")
    product = Drugs::Product.new
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.product = product
    sequence.atc = Drugs::Atc.new('N04BB01')
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
  def teardown
    super
    ODDB.config.remote_databases = []
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

    @selenium.click "//a[@name='th_company']"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", 
                 @selenium.get_title

    @selenium.click "//a[@name='th_price_festbetrag']"
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
    assert_equal "ODDB | Medikamente | Details | Amantadin by Producer", 
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
  def test_search__remote_not_enabled
    remote = flexmock('Remote')
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    package = setup_package
    open "/"
    assert_equal "ODDB | Medikamente | Home", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_0"))
    assert !is_element_present("//a[@id='cid_1']")
    assert is_text_present('Gelb = Zuzahlungsbefreit')
    assert !is_text_present('Rot = CH - Produkte')
  ensure
    drb.stop_service
  end
  def test_search__remote
    remote = flexmock('Remote')
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    remote.should_receive(:get_currency_rate).with('EUR').and_return 0.6
    rpackage = flexmock('Remote Package')
    remote.should_receive(:remote_packages).and_return([rpackage])
    rpackage.should_receive(:name_base).and_return('Remotadin')
    rpackage.should_receive(:price_public).and_return(1200)
    rpackage.should_receive(:comparable_size)\
      .and_return(Drugs::Dose.new(100, 'ml'))
    rpackage.should_receive(:__drbref).and_return("55555")
    rpackage.should_receive(:comform)
    rcompany = flexmock('Remote Company')
    rpackage.should_receive(:company).and_return(rcompany)
    rcompany.should_receive(:name).and_return('Producer (Schweiz) AG')
    ratc = flexmock('Remote Atc Class')
    rpackage.should_receive(:atc_class).and_return(ratc)
    ratc.should_receive(:code).and_return('N04BB01')
    ratc.should_receive(:de).and_return('Amantadine')
    ragent = flexmock('Remote ActiveAgent')
    rpackage.should_receive(:active_agents).and_return([ragent])
    rsubstance = flexmock('Remote Substance')
    ragent.should_receive(:dose).and_return(Drugs::Dose.new(100, 'mg'))
    ragent.should_receive(:substance).and_return(rsubstance)
    rsubstance.should_receive(:de).and_return('Amantadinum')

    package = setup_package
    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "ODDB | Medikamente | Home", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_0"))
    assert is_element_present("//a[@id='cid_1']")
    assert_match(/^Remotadin/, get_text("cid_1"))
    assert is_text_present('Producer (Schweiz) AG')
    assert is_text_present('7.20')
    assert_equal 'zuzahlungsbefreit', get_attribute('//tr[2]@class')
    assert_equal 'remote bg', get_attribute('//tr[3]@class')

    ## ensure sortable
    click "link=Präparat"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
    assert_match(/^Remotadin/, get_text("cid_0"))
    assert_match(/^Amantadin by Producer/, get_text("cid_1"))
    assert_equal 'remote', get_attribute('//tr[2]@class')
    assert_equal 'zuzahlungsbefreit bg', get_attribute('//tr[3]@class')

    click "link=Wirkstoff"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_0"))
    assert_match(/^Remotadin/, get_text("cid_1"))
    assert_equal 'zuzahlungsbefreit', get_attribute('//tr[2]@class')
    assert_equal 'remote bg', get_attribute('//tr[3]@class')

    assert is_text_present('Gelb = Zuzahlungsbefreit')
    assert is_text_present('Rot = CH - Produkte')
  ensure
    drb.stop_service
  end
  def test_search__remote__no_link
    remote = flexmock('Remote')
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    remote.should_receive(:get_currency_rate).with('EUR').and_return 0.6
    rpackage = flexmock('Remote Package')
    remote.should_receive(:remote_packages).and_return([rpackage])
    rpackage.should_receive(:name_base).and_return('Remotadin')
    rpackage.should_receive(:price_public).and_return(1200)
    rpackage.should_receive(:comparable_size)\
      .and_return(Drugs::Dose.new(100, 'ml'))
    rpackage.should_receive(:__drbref).and_return("55555")
    rpackage.should_receive(:comform)
    rcompany = flexmock('Remote Company')
    rpackage.should_receive(:company).and_return(rcompany)
    rcompany.should_receive(:name).and_return('Producer (Schweiz) AG')
    ratc = flexmock('Remote Atc Class')
    rpackage.should_receive(:atc_class).and_return(ratc)
    ratc.should_receive(:code).and_return('N04BB01')
    ratc.should_receive(:de).and_return('Amantadine')
    ragent = flexmock('Remote ActiveAgent')
    rpackage.should_receive(:active_agents).and_return([ragent, ragent])
    rsubstance = flexmock('Remote Substance')
    ragent.should_receive(:dose).and_return(Drugs::Dose.new(100, 'mg'))
    ragent.should_receive(:substance).and_return(rsubstance)
    rsubstance.should_receive(:de).and_return('Amantadinum')

    package = setup_package
    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "ODDB | Medikamente | Home", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
    assert !is_element_present("//a[@id='cid_1']")
  ensure
    drb.stop_service
  end
  def test_search__remote__connection_error
    ODDB.config.remote_databases = ['druby://localhost:999999']

    package = setup_package
    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "ODDB | Medikamente | Home", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_0"))
    assert !is_element_present("//a[@id='cid_1']")
    assert !is_text_present('Producer (Schweiz) AG')
    assert !is_text_present('7.20')
  end
end
  end
end
