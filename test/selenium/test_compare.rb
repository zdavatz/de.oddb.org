#!/usr/bin/env ruby
# Selenium::TestCompare -- de.oddb.org -- 15.02.2007 -- hwyss@ywesee.com


$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'
require 'odba/drbwrapper'
require 'odba'

module ODDB
  module Selenium
class TestCompare < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::Package.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
    @cache = flexstub(ODBA.cache)
    super
  end
  def setup_package(name, pzn='12345', price=6)
    product = Drugs::Product.new
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.atc = Drugs::Atc.new('N04BB01')
    sequence.product = product
    composition = Drugs::Composition.new
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = 'Amantadin'
    dose = Drugs::Dose.new(100, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    composition.add_active_agent(active_agent)
    galform = Drugs::GalenicForm.new
    galform.description.de = 'Tropfen'
    composition.galenic_form = galform
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
    package.name.de = name
    package.sequence = sequence
    package.add_price(Util::Money.new(price, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.add_code(Util::Code.new(:cid, pzn, 'DE'))
    package.save
    package
  end
  def setup_remote_package(name, uid='55555', price=12)
    rpackage = flexmock('Remote Package')
    rpackage.should_receive(:name_base).and_return(name)
    rpackage.should_receive(:price_public).and_return {
      price * 100 if(price)
    }
    rpackage.should_receive(:comparable_size)\
      .and_return(Drugs::Dose.new(4))
    rpackage.should_receive(:__drbref).and_return(uid)
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
    rgalform = flexmock('Remote Galenic Form')
    rpackage.should_receive(:galenic_form).and_return(rgalform)
    rgalform.should_receive(:de).and_return('Tropfen')
    rgroup = flexmock('Remote Galenic Group')
    rgroup.should_receive(:de).and_return('Unbekannt')
    rgalform.should_receive(:galenic_group).and_return(rgroup)
    @cache.should_receive(:fetch).with(uid.to_i).and_return(rpackage)
    rpackage
  end
  def teardown
    super
    ODDB.config.remote_databases = []
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
    assert is_text_present('Gelb = Zuzahlungsbefreit')
    assert !is_text_present('Rot = CH - Produkte')
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
  def test_remote
    remote = flexmock('Remote')
    DRb.install_id_conv(ODBA::DRbIdConv.new)
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    remote.should_receive(:get_currency_rate).with('EUR').and_return 0.6
    rpackage = setup_remote_package('Remotadin', '55555', 12)
    remote.should_receive(:remote_packages).and_return([rpackage])

    rother = setup_remote_package('Remoteric', '55556', nil)
    rpackage.should_receive(:comparables).and_return([rother])


    package = setup_package('Amantadin')
    ## switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "ODDB | Medikamente | Home", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
  
    atc = Drugs::Atc.new('N04BB01')

    rother.should_receive(:comparables).and_return([rpackage])
    click "link=Remotadin"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Preisvergleich | Remotadin", 
                 get_title
    assert_match(/^Remotadin/, get_text("cid_"))
    assert is_element_present("//a[@id='cid_0']")
    assert_match(/^Amantadin/, get_text("cid_0"))
    assert is_element_present("//a[@id='cid_1']")
    assert_match(/^Remoteric/, get_text("cid_1"))
    assert is_text_present('-39.7%')
    #assert is_text_present('-16.6%')

    click "link=Remoteric"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Preisvergleich | Remoteric", 
                 get_title
    assert_match(/^Remoteric/, get_text("cid_"))
    assert is_element_present("//a[@id='cid_0']")
    assert_match(/^Amantadin/, get_text("cid_0"))
    assert is_element_present("//a[@id='cid_1']")
    assert_match(/^Remotadin/, get_text("cid_1"))

    assert is_text_present('Gelb = Zuzahlungsbefreit')
    assert is_text_present('Rot = CH - Produkte')
  ensure
    drb.stop_service
  end
  def test_remote__reversed
    remote = flexmock('Remote')
    DRb.install_id_conv(ODBA::DRbIdConv.new)
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    remote.should_receive(:get_currency_rate).with('EUR').and_return 0.6
    rpackage = setup_remote_package('Remotadin', '55555', 12)
    remote.should_receive(:remote_packages).and_return([rpackage])

    rother = setup_remote_package('Remoteric', '55556', nil)
    remote.should_receive(:remote_comparables).with(ODBA::DRbWrapper)\
      .and_return([rpackage, rother])

    package = setup_package('Amantadin')
    ## switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "ODDB | Medikamente | Home", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | Amantadin", get_title
  
    atc = Drugs::Atc.new('N04BB01')

    rother.should_receive(:comparables).and_return([rpackage])
    click "link=Amantadin"
    wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Preisvergleich | Amantadin", 
                 get_title
    assert_match(/^Amantadin/, get_text("cid_"))
    assert is_element_present("//a[@id='cid_0']")
    assert_match(/^Remotadin/, get_text("cid_0"))
    assert is_element_present("//a[@id='cid_1']")
    assert_match(/^Remoteric/, get_text("cid_1"))
    assert is_text_present('+65.8%')
  ensure
    drb.stop_service
  end
end
  end
end
