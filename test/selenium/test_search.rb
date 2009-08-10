#!/usr/bin/env ruby
# Selenium::TestSearch -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'odba/drbwrapper'
require 'odba'
require 'oddb/drugs'
require 'oddb/util'
require 'stub/model'

module ODDB
  module Selenium
class TestSearch < Test::Unit::TestCase
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
  def setup_remote_package(name, uid='55555', price=12, ikscat='B')
    rpackage = flexmock('Remote Package')
    rpackage.should_receive(:barcode).and_return("7680#{uid}0012")
    rpackage.should_receive(:name_base).and_return(name)
    rpackage.should_receive(:price_public).and_return {
      price
    }
    rpackage.should_receive(:ikscat).and_return(ikscat)
    rpackage.should_receive(:sl_entry).and_return(true)
    rpackage.should_receive(:comparable_size)\
      .and_return(Drugs::Dose.new(100, 'ml'))
    rpackage.should_receive(:__drbref).and_return(uid)
    rcompany = flexmock('Remote Company')
    rpackage.should_receive(:company).and_return(rcompany)
    rcompany.should_receive(:name).and_return('Producer (Schweiz) AG')
    ratc = flexmock('Remote Atc Class')
    ratc.should_receive(:ddds).and_return []
    rpackage.should_receive(:atc_class).and_return(ratc)
    ratc.should_receive(:code).and_return('N04BB01')
    ratc.should_receive(:parent_code).and_return('N04BB')
    flexmock(Drugs::Atc).should_receive(:find_by_code)
    ratc.should_receive(:name).and_return("Rem\366tadine")
    #ratc.should_receive(:de).and_return('Amantadine')
    ragent = flexmock('Remote ActiveAgent')
    rpackage.should_receive(:active_agents).and_return([ragent])
    rsubstance = flexmock('Remote Substance')
    ragent.should_receive(:dose).and_return(Drugs::Dose.new(100, 'mg'))
    ragent.should_receive(:substance).and_return(rsubstance)
    rsubstance.should_receive(:de).and_return('Amantadinum')
    rgalform = flexmock('Remote Galenic Form')
    rpackage.should_receive(:galenic_forms).and_return([rgalform])
    rgalform.should_receive(:de).and_return('Tropfen')
    rgroup = flexmock('Remote Galenic Group')
    rgroup.should_receive(:de).and_return('Unbekannt')
    rgalform.should_receive(:galenic_group).and_return(rgroup)
    rpart = flexmock('Remote Part')
    rpart.should_receive(:comparable_size)\
      .and_return(Drugs::Dose.new(4))
    rpart.should_ignore_missing
    rpackage.should_receive(:parts).and_return [rpart]
    @cache.should_receive(:fetch).with(uid.to_i).and_return(rpackage)
    rpackage.should_ignore_missing
    rpackage
  end
  def teardown
    super
    ODDB.config.remote_databases = []
    @currency.stop_service
  end
  def test_search
    ODDB.config.query_limit = 20
    package = setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('100 mg')
    assert is_text_present('5 Ampullen à 20 ml')
    assert is_text_present('6.00')
    assert is_text_present('10.00')
    assert is_text_present('-4.00')
    assert is_text_present('3')
    assert is_text_present('Ja')
    assert is_text_present('N04BB01')
    assert is_text_present('Producer AG')
    assert is_text_present('FB')

    ## State::Drugs::Result does not re-search if the query is the same
    package2 = Drugs::Package.new
    package2.sequence = package.sequence
    package2.save
    package2.add_price(Util::Money.new(999999, :public, 'DE'))
    open('/de/drugs/search/query/Amantadin')
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')
    assert !is_text_present('999999.00')

    ## Sort result
    click "//a[@name='th_package_infos']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title

    click "//a[@name='th_package_infos']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title

    click "//a[@name='th_ddd_prices']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title

    click "//a[@name='th_company']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title

    click "//a[@name='th_price_festbetrag']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title

    ## an empty Result:
    type "query", "Gabapentin"
    select "dstype", "Inhaltsstoff"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Gabapentin | Inhaltsstoff | Open Drug Database", 
                 get_title
    expected = <<-EOS
Ihr Such-Stichwort hat zu keinem Suchergebnis geführt. Bitte überprüfen Sie die Schreibweise und versuchen Sie es noch einmal.
    EOS
    assert is_text_present(expected.chop)
  end
  def test_search__ajax
    setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Producer"
    select 'dstype', 'Preisvergleich'
    # no click necessary
    # click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Producer | Preisvergleich | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')
    mouse_over 'package_infos12345'
    assert !60.times { 
      break if (is_element_present("//body/div[5]/table") rescue false)
      sleep 1 
    }
    assert is_text_present('Festbetragsgruppe')
    assert is_text_present('Festbetragsstufe')
    assert is_text_present('3: Arzneimittel mit therapeutisch vergleichbarer Wirkung, insbesondere Arzneimittelkombinationen')
    assert is_text_present('Zuzahlungsbefreit')
    assert is_text_present('Ja')
    assert is_text_present('Rezeptpflichtig')
    assert is_text_present('Nein')
    mouse_over 'ddd_price_12345.0'
    assert !60.times { 
      break if (is_element_present("//body/div[6]/table") rescue false)
      sleep 1 
    }
    assert is_text_present('Verabreichungsform')
    assert is_text_present('Oral')
    assert is_text_present('Anmerkung')
    assert is_text_present('Tagesdosis')
    assert is_text_present('10 mg')
    assert is_text_present('Apothekenverkaufspreis')
    assert is_text_present('6.00')
    assert is_text_present('Stärke')
    assert is_text_present('100 mg')
    assert is_text_present('Packungsgrösse')
    assert is_text_present('5 Ampullen à 20 ml')
    assert is_text_present('Berechnung')
    assert is_text_present('( 10 mg / 100 mg ) x ( 6.00 / 5 Ampullen à 20 ml ) = EUR 0.01 / Tag')
  end
  def test_search__company
    setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Producer"
    select 'dstype', 'Zulassungsinhaber'
    # no click necessary
    # click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Producer | Zulassungsinhaber | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('100 mg')
    assert is_text_present('5 Ampullen à 20 ml')
    assert is_text_present('6.00')
    assert is_text_present('10.00')
    assert is_text_present('-4.00')
    assert is_text_present('3')
    assert is_text_present('Ja')
    assert is_text_present('N04BB01')
    assert is_text_present('Producer AG')
  end
  def test_search__compare
    setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "amantadin"
    select 'dstype', 'Preisvergleich'
    # no click necessary
    # click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('100 mg')
    assert is_text_present('5 Ampullen à 20 ml')
    assert is_text_present('6.00')
    assert is_text_present('10.00')
    assert is_text_present('-4.00')
    assert is_text_present('3')
    assert is_text_present('Ja')
    assert is_text_present('N04BB01')
    assert is_text_present('Producer AG')
  end
  def test_search__details
    package = setup_package
    package.add_code(Util::Code.new(:cid, '12345', 'DE'))
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')

    ## click through to Details
    click "link=Amantadin 100 mg"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Details | Amantadin by Producer | Open Drug Database", 
                 get_title

    ## click back to Result
    click "link=Suchresultat"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
  end
  def test_search__direct_sort
    setup_package("Amonamon")
    setup_package("Nomamonamon")
    open "/de/drugs/search/query/Producer/dstype/compare/sortvalue/product"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Producer | Preisvergleich | Open Drug Database", 
                 get_title

    assert_match(/^Nomamonamon/, get_text("cid_N04BB01_0"))
    assert_match(/^Amonamon/, get_text("cid_N04BB01_1"))
  end
  def test_search__feedback
    package = setup_package
    package.add_code(Util::Code.new(:cid, '12345', 'DE'))
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')

    ## click through to Feedback
    assert is_element_present("link=FB")
    click "//a[@name='feedback_short']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Feedback | Amantadin by Producer | Open Drug Database", 
                 get_title

    ## click back to Result
    click "link=Suchresultat"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
  end
  def test_search__limited
    ODDB.config.query_limit = 1
    package = setup_package
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    open "/de/drugs/search/query/Amantadin"
    assert_equal 'DE - ODDB.org | Medikamente | Open Drug Database', 
                 get_title
    assert is_text_present("Abfragebeschränkung")
  ensure
    ODDB.config.query_limit = 20
  end
  def test_search__admin_not_limited
    ODDB.config.query_limit = 1
    package = setup_package
    user = login_admin
    2.times {
      open "/de/drugs/search/query/Amantadin"
      assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                   get_title
    }
  ensure
    ODDB.config.query_limit = 20
  end
  def test_search__admin_atc
    existing = setup_package
    package = setup_package
    package.sequence.atc = nil
    user = login_admin
    open "/de/drugs/search/query/Amantadin"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Preisvergleich | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert is_text_present('ATC-Code nicht bekannt - 1 Präparate')
    assert is_element_present("atc-assign")
    assert is_element_present("atc-assign-toggle")
    assert is_element_present("atc-assign-form")
    assert !is_visible("atc-assign")
    click "link=ATC zuweisen"
    assert is_visible("atc-assign")
    
    type "atc-assign", "N04BB02"
    submit "atc-assign-form"
    wait_for_page_to_load "30000"

    assert is_text_present('Der ATC-Code "N04BB02" ist nicht bekannt.')
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert is_text_present('ATC-Code nicht bekannt - 1 Präparate')
    assert is_element_present("atc-assign")
    assert is_element_present("atc-assign-toggle")
    assert is_element_present("atc-assign-form")
    assert is_visible("atc-assign")

    type "atc-assign", "N04BB01"
    submit "atc-assign-form"
    wait_for_page_to_load "30000"

    assert is_text_present('Amantadin (N04BB01) - 2 Präparate')
    assert !is_text_present('ATC-Code nicht bekannt')
    assert !is_element_present("atc-assign")
    assert !is_element_present("atc-assign-toggle")
    assert !is_element_present("atc-assign-form")
  ensure
    ODDB.config.query_limit = 20
  end
  def test_search__with_fachinfo
    package = setup_package
    package.fachinfo.de = "Fachinfo-Document"
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present('FI')
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('100 mg')
    assert is_text_present('5 Ampullen à 20 ml')
    assert is_text_present('6.00')
    assert is_text_present('10.00')
    assert is_text_present('-4.00')
    assert is_text_present('3')
    assert is_text_present('Ja')
    assert is_text_present('N04BB01')
    assert is_text_present('Producer AG')
  end
  def test_search__multiple_substances
    package = setup_package
    substance = Drugs::Substance.new
    substance.name.de = "Propranolol"
    dose = Drugs::Dose.new(50, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    package.sequence.compositions.first.add_active_agent(active_agent)
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('2 Wirkstoffe')
  end
  def test_search__paged
    pack = setup_package
    other = setup_package('Amantadin Ophtal', 'S01AA01')
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    flexstub(@server['test:preset-session-id']).should_receive(:pagelength).and_return(1)
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present('Alle Präparate anzeigen')
    assert !is_text_present('Zur ATC-Übersicht')
    assert !is_text_present('<< 1 2 >>')
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert !is_text_present('Amantadin by Producer')
    assert is_text_present('Amantadin (S01AA01) - 1 Präparate')
    assert !is_text_present('Amantadin Ophtal')

    click 'link=Alle Präparate anzeigen'
    wait_for_page_to_load "30000"
    assert !is_text_present('Alle Präparate anzeigen')
    assert is_text_present('Zur ATC-Übersicht')
    assert is_text_present('<< 1 2 >>')
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert is_text_present('Amantadin by Producer')
    assert !is_text_present('Amantadin (S01AA01) - 1 Präparate')
    assert !is_text_present('Amantadin Ophtal')

    click 'link=>>'
    wait_for_page_to_load "30000"
    assert !is_text_present('Alle Präparate anzeigen')
    assert is_text_present('Zur ATC-Übersicht')
    assert is_text_present('<< 1 2 >>')
    assert !is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert !is_text_present('Amantadin by Producer')
    assert is_text_present('Amantadin (S01AA01) - 1 Präparate')
    assert is_text_present('Amantadin Ophtal')

    click 'link=Zur ATC-Übersicht'
    wait_for_page_to_load "30000"
    assert is_text_present('Alle Präparate anzeigen')
    assert !is_text_present('Zur ATC-Übersicht')
    assert !is_text_present('<< 1 2 >>')
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert !is_text_present('Amantadin by Producer')
    assert is_text_present('Amantadin (S01AA01) - 1 Präparate')
    assert !is_text_present('Amantadin Ophtal')

    click 'link=Amantadin (N04BB01) - 1 Präparate'
    wait_for_page_to_load "30000"
    assert is_text_present('Alle Präparate anzeigen')
    assert !is_text_present('Zur ATC-Übersicht')
    assert !is_text_present('<< 1 2 >>')
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('Amantadin (S01AA01) - 1 Präparate')
    assert !is_text_present('Amantadin Ophtal')

    click 'link=Amantadin (S01AA01) - 1 Präparate'
    wait_for_page_to_load "30000"
    assert is_text_present('Alle Präparate anzeigen')
    assert !is_text_present('Zur ATC-Übersicht')
    assert !is_text_present('<< 1 2 >>')
    assert is_text_present('Amantadin (N04BB01) - 1 Präparate')
    assert !is_text_present('Amantadin by Producer')
    assert is_text_present('Amantadin (S01AA01) - 1 Präparate')
    assert is_text_present('Amantadin Ophtal')
  end
  def test_search__remote_not_enabled
    remote = flexmock('Remote')
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    package = setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_N04BB01_0"))
    assert !is_element_present("//a[@id='cid_N04BB01_1']")
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
    rpackage = setup_remote_package 'Remotadin'
    remote.should_receive(:remote_packages).and_return([rpackage])

    package = setup_package
    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "CH | DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "CH | DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_N04BB01_0"))
    assert is_element_present("//a[@id='cid_N04BB01_1']")
    assert_match(/^Remotadin/, get_text("cid_N04BB01_1"))
    assert is_text_present('Producer (Schweiz) AG')
    assert is_text_present('10.80')
    assert_equal 'groupheader', get_attribute('//tr[2]@class')
    assert_equal 'zuzahlungsbefreit', get_attribute('//tr[3]@class')
    assert_equal 'remote bg', get_attribute('//tr[4]@class')

    ## ensure sortable
    click "link=Präparat"
    wait_for_page_to_load "30000"
    assert_equal "CH | DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert_match(/^Remotadin/, get_text("cid_N04BB01_0"))
    assert_match(/^Amantadin by Producer/, get_text("cid_N04BB01_1"))
    assert_equal 'groupheader', get_attribute('//tr[2]@class')
    assert_equal 'remote', get_attribute('//tr[3]@class')
    assert_equal 'zuzahlungsbefreit bg', get_attribute('//tr[4]@class')

    click "link=Wirkstoff"
    wait_for_page_to_load "30000"
    assert_equal "CH | DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_N04BB01_0"))
    assert_match(/^Remotadin/, get_text("cid_N04BB01_1"))
    assert_equal 'groupheader', get_attribute('//tr[2]@class')
    assert_equal 'zuzahlungsbefreit', get_attribute('//tr[3]@class')
    assert_equal 'remote bg', get_attribute('//tr[4]@class')

    assert is_text_present('Gelb = Zuzahlungsbefreit')
    assert is_text_present('Rot = CH - Produkte')
  ensure
    drb.stop_service
  end
  def test_search__remote__ajax
    remote = flexmock('Remote')
    DRb.install_id_conv(ODBA::DRbIdConv.new)
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    remote.should_receive(:get_currency_rate).with('EUR').and_return 0.6
    rpackage = setup_remote_package('Remotadin')
    rotc = setup_remote_package('Remotadin OTC', '55556', 24, 'D')
    remote.should_receive(:remote_packages).and_return([rpackage, rotc])

    package = setup_package
    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "CH | DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "CH | DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert_match(/^Remotadin/, get_text("cid_N04BB01_1"))
    mouse_over 'package_infos0.55555'
    assert !60.times { 
      break if (is_element_present("//body/div[5]/table") rescue false)
      sleep 1 
    }
    assert is_text_present('B : Abgabe auf ärztliche Verschreibung')

    mouse_over 'explain_price12345'
    assert !60.times { 
      break if (is_element_present("//body/div[6]/table") rescue false)
      sleep 1 
    }
    assert is_text_present('Preis Deutschland (CHF)')
    assert is_text_present('9.00')
    assert is_text_present('MwSt. Deutschland (19%)')
    assert is_text_present('- 1.44')
    assert is_text_present('MwSt. Schweiz (7.6%)')
    assert is_text_present('+ 0.57')
    assert is_text_present('Preis Schweiz (CHF)')
    assert is_text_present('8.14')

    assert_match(/^Remotadin/, get_text("cid_N04BB01_2"))
    mouse_over 'package_infos0.55556'
    assert !60.times { 
      break if (is_element_present("//body/div[7]/table") rescue false)
      sleep 1 
    }
    assert is_text_present('D : Abgabe nach Fachberatung')

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
    rpackage.should_receive(:barcode).and_return('Barcode')
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
    ratc.should_receive(:ddds).and_return []
    ratc.should_receive(:code).and_return('N04BB01')
    ratc.should_receive(:de).and_return('Amantadine')
    ragent = flexmock('Remote ActiveAgent')
    rpackage.should_receive(:active_agents).and_return([ragent, ragent])
    rsubstance = flexmock('Remote Substance')
    ragent.should_receive(:dose).and_return(Drugs::Dose.new(100, 'mg'))
    ragent.should_receive(:substance).and_return(rsubstance)
    rpart = flexmock('Remote Part')
    rpart.should_receive(:comparable_size)\
      .and_return(Drugs::Dose.new(4))
    rpart.should_ignore_missing
    rpackage.should_receive(:parts).and_return [rpart]
    rpackage.should_receive(:galenic_forms).and_return []
    rsubstance.should_receive(:de).and_return('Amantadinum')
    rpackage.should_ignore_missing

    package = setup_package
    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "CH | DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "CH | DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert !is_element_present("//a[@id='cid_N04BB01_1']")
  ensure
    drb.stop_service
  end
  def test_search__remote__only_remote
    remote = flexmock('Remote')
    drb = DRb.start_service('druby://localhost:0', remote)
    ODDB.config.remote_databases = [drb.uri]

    remote.should_receive(:get_currency_rate).with('EUR').and_return 0.6
    rpackage = setup_remote_package 'Remotadin'
    remote.should_receive(:remote_packages).and_return([rpackage])

    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "CH | DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "CH | DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert is_element_present("//a[@id='cid_N04BB01_0']")
    assert_match(/^Remotadin/, get_text("cid_N04BB01_0"))
    assert is_text_present('Remötadin')
    assert is_text_present('Producer (Schweiz) AG')
    assert is_text_present('10.80')

  ensure
    drb.stop_service
  end
  def test_search__remote__connection_error
    ODDB.config.remote_databases = ['druby://localhost:999999']

    package = setup_package
    # switch to mm-flavor
    open "/de/drugs/home/flavor/mm"
    assert_equal "CH | DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "CH | DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", get_title
    assert_match(/^Amantadin by Producer/, get_text("cid_N04BB01_0"))
    assert !is_element_present("//a[@id='cid_N04BB01_1']")
    assert !is_text_present('Producer (Schweiz) AG')
    assert !is_text_present('7.20')
  end
  def test_search__short
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "A"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | A | Markenname | Open Drug Database", 
                 get_title
    expected = 'Ihr Such-Stichwort ergibt ein sehr grosses Resultat. Bitte verwenden Sie mindestens 3 Buchstaben.'
    assert is_text_present(expected)
  end
  def test_search__substance
    pack = setup_package
    flexstub(pack).should_receive(:substance).and_return('Amantadin')
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "amantadin"
    select 'dstype', 'Inhaltsstoff'
    # no click necessary
    # click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | amantadin | Inhaltsstoff | Open Drug Database", 
                 get_title
    assert is_text_present('Amantadin by Producer')
    assert is_text_present('100 mg')
    assert is_text_present('5 Ampullen à 20 ml')
    assert is_text_present('6.00')
    assert is_text_present('10.00')
    assert is_text_present('-4.00')
    assert is_text_present('3')
    assert is_text_present('Ja')
    assert is_text_present('N04BB01')
    assert is_text_present('Producer AG')
  end
  def test_search__export_csv
    pack = setup_package
    ODDB.config.query_limit = 20
    package = setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_element_present '//input[@name="export_csv"]'
    click '//input[@name="export_csv"]'
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | CSV-Export | Amantadin | Markenname | Open Drug Database", 
                 get_title

    assert is_text_present("CSV-Export Datenerfassung")
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

    assert is_text_present("2 x")
    assert is_text_present("Amantadin_tradename.csv")

    refresh
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | CSV-Export | Amantadin | Markenname | Open Drug Database", 
                 get_title

    assert is_text_present("CSV-Export Datenerfassung")
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

    assert is_text_present("2 x")
    assert is_text_present("Amantadin_tradename.csv")

  end
  def test_search__export_csv__step2_error
    pack = setup_package
    ODDB.config.query_limit = 20
    package = setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_element_present '//input[@name="export_csv"]'
    click '//input[@name="export_csv"]'
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | CSV-Export | Amantadin | Markenname | Open Drug Database", 
                 get_title

    assert is_text_present("CSV-Export Datenerfassung")
    assert is_text_present('Bitte geben Sie Ihre persönlichen Angaben ein und wählen Sie einen Benutzernamen und ein Passwort.')

    @auth.should_receive(:login).and_return { raise Yus::UnknownEntityError }
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | CSV-Export | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_text_present("Bitte füllen Sie alle Felder aus.")
    %w{email pass confirm_pass salutation name_last name_first}.each { |key|
      assert_equal "error", get_attribute("//label[@for='#{key}']@class")
    }
  end
  def test_search__export_csv__step2
    yus = flexmock("yus-server")
    remote = DRb.start_service('druby://localhost:0', yus)
    yus_session = setup_autosession(yus)
    yus_session.should_receive(:get_entity_preferences).and_return({})
    email = "downloader@oddb.org"
    ODDB.config.auth_server = remote.uri

    pack = setup_package
    ODDB.config.query_limit = 20
    package = setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_element_present '//input[@name="export_csv"]'
    click '//input[@name="export_csv"]'
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | CSV-Export | Amantadin | Markenname | Open Drug Database", 
                 get_title

    assert is_text_present("CSV-Export Datenerfassung")
    assert is_text_present('Bitte geben Sie Ihre persönlichen Angaben ein und wählen Sie einen Benutzernamen und ein Passwort.')

    @auth.should_receive(:login).and_return { raise Yus::UnknownEntityError }
    type "email", email
    type "pass", "secret"
    type "confirm_pass", "secret"
    select "//select[@name='salutation']", "Herr"
    type "name_last", "Test"
    type "name_first", "Fritz"

    yus_session.should_receive(:create_entity).with(email, "5ebe2294ecd0e0f08eab7690d2a6ee69")
    user = mock_user email
    ODDB.server = server = flexmock("server")
    server.should_receive(:login).and_return(user)
    @auth.should_receive(:login).and_return(user)

    click "//input[@type='submit']"
    wait_for_page_to_load "30000"

    output = @http_server.redirected_output 
    assert_match /www.sandbox.paypal.com/, output
  end
  def test_search__export_csv__direct
    pack = setup_package
    user = login 'test.export@oddb.org', ['download', 'org.oddb.de.Amantadin_tradename.csv']
    ODDB.config.query_limit = 20
    package = setup_package
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    type "query", "Amantadin"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Suchen | Amantadin | Markenname | Open Drug Database", 
                 get_title
    assert is_element_present '//input[@name="export_csv"]'
    click '//input[@name="export_csv"]'

    assert @http_server.attachment
  end
end
  end
end
