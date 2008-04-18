#!/usr/bin/env ruby
# Selenium::TestSequence -- de.oddb.org -- 15.04.2008 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'
require 'oddb/import/pharmnet'

module ODDB
  module Selenium
class TestAdminSequence < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::ActiveAgent.instances.clear
    Drugs::Composition.instances.clear
    Drugs::Sequence.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
    super
  end
  def setup_sequence(registration = '12345.0')
    product = Drugs::Product.new
    product.name.de = "Product"
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.atc = Drugs::Atc.new('N04BB01')
    sequence.atc.name.de = 'Amantadin'
    sequence.add_code Util::Code.new(:registration, registration, 'EU')
    ddd = Drugs::Ddd.new('O')
    ddd.dose = Drugs::Dose.new(5, 'mg')
    sequence.atc.add_ddd(ddd)
    sequence.product = product
    composition = Drugs::Composition.new
    composition.equivalence_factor = '44.6'
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = "Amantadin"
    substance.save
    dose = Drugs::Dose.new(100, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    composition.add_active_agent(active_agent)
    sequence.save
    sequence
  end
  def test_sequence
    sequence = setup_sequence
    user = login_admin
    uid = sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title
    assert is_element_present("atc")
    assert is_element_present("registration")
    assert is_element_present("fi_url")
    assert is_element_present("pi_url")
    assert is_element_present("update")
    assert is_element_present("delete")

    assert_equal "N04BB01", get_value("atc")
    assert_equal "12345.0", get_value("registration")

    assert is_element_present("link=-")
    assert is_element_present("substance[0][0]")
    assert is_element_present("dose[0][0]")
    assert is_element_present("link=+")

    assert_equal "Amantadin", get_value("substance[0][0]")
    assert_equal "100 mg", get_value("dose[0][0]")
  end
  def test_sequence__update__error
    sequence = setup_sequence
    other = setup_sequence('54321.5')
    other.save
    user = login_admin
    uid = sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    assert_equal "N04BB01", get_value("atc")
    assert_equal "12345.0", get_value("registration")

    type 'registration', '54321.5'
    type 'atc', 'A01AA01'

    click "//input[@name='update']"
    wait_for_page_to_load "30000"

    assert is_text_present('Der ATC-Code "A01AA01" ist nicht bekannt.')
    assert is_text_present("Die EU-Registrationsnummer '54321.5' (Product) ist bereits vergeben.")

    assert_equal 'N04BB01', get_value('atc')
    assert !is_text_present('Amantadin')
    assert is_element_present('atc_name')
    assert_equal '12345.0', get_value('registration')
    
    assert_equal('12345.0', sequence.code(:registration, 'EU').value)

    [:atc, :fi_url, :pi_url, :registration].each { |key|
      assert_not_equal 'test.admin@oddb.org', sequence.data_origin(key)
    }

    type 'atc', 'A01AA01'
    type 'atc_name', 'new ATC-Code'

    click "//input[@name='update']"
    wait_for_page_to_load "30000"
    assert !is_text_present('Der ATC-Code "A01AA01" ist nicht bekannt.')
    assert is_text_present('new ATC-Code')
    assert_equal 'A01AA01', get_value('atc')
    
    atc = sequence.atc
    assert_equal 'A01AA01', atc.code
    assert_equal 'new ATC-Code', atc.name.de
    assert_equal [sequence], atc.sequences
    assert atc.saved?
  end
  def test_sequence__update__success
    sequence = setup_sequence
    user = login_admin
    uid = sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    assert is_element_present("atc")

    assert is_element_present("registration")
    assert is_element_present("fi_url")
    assert is_element_present("pi_url")
    assert is_element_present("update")
    assert is_element_present("delete")

    assert_equal "N04BB01", get_value("atc")
    assert_equal "12345.0", get_value("registration")

    atc = Drugs::Atc.new('A01AA01')
    atc.name.de = "Assigned Atc-Class"
    atc.save

    type 'registration', '54321.5'
    type 'atc', 'A01AA01'

    fachinfo = "A Fachinfo-Document"
    fi_url = "http://host.domain/fi_path.rtf"
    type "fi_url", fi_url
    patinfo = "A Patinfo-Document"
    pi_url = "http://host.domain/pi_path.rtf"
    type "pi_url", pi_url

    flexmock(Import::PharmNet::Import).new_instances\
      .should_receive(:import_rtf).and_return { |key, agent, url, term|
      assert_instance_of WWW::Mechanize, agent
      assert_equal 'Product', term
      case key
      when :fachinfo
        assert_equal fi_url, url
        fachinfo
      when :patinfo
        assert_equal pi_url, url
        patinfo
      else
        flunk "import_rtf was called with invalid key: #{key.inspect}"
      end
    }

    click "//input[@name='update']"
    wait_for_page_to_load "30000"

    assert !is_text_present('Der ATC-Code "A01AA01" ist nicht bekannt.')
    assert !is_text_present("Die EU-Registrationsnummer '54321.5' (Product) ist bereits vergeben.")

    assert_equal 'A01AA01', get_value('atc')
    assert is_text_present('Assigned Atc-Class')
    assert_equal '54321.5', get_value('registration')
    assert is_text_present("FI")
    assert is_text_present("GI")
    
    assert_equal(atc, sequence.atc)
    assert_equal('54321.5', sequence.code(:registration, 'EU').value)
    assert_equal(fachinfo, sequence.fachinfo.de)
    assert_equal(patinfo, sequence.patinfo.de)

    [:atc, :fi_url, :pi_url, :registration].each { |key|
      assert_equal 'test.admin@oddb.org', sequence.data_origin(key)
    }

  end
  def test_sequence__delete
    sequence = setup_sequence
    user = login_admin
    uid = sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    click "link=Produkt"
    wait_for_page_to_load "30000"
    link_loc = "link=#{uid}"

    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{sequence.product.uid} | Open Drug Database", get_title
    assert is_element_present(link_loc)
    click link_loc
    wait_for_page_to_load "30000"

    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title

    click "delete"
    assert_equal "Wollen Sie diese Sequenz wirklich löschen?", get_confirmation

    wait_for_page_to_load "30000"

    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{sequence.product.uid} | Open Drug Database", get_title
    assert !is_element_present(link_loc)
  end
  def test_sequence__active_agents
    sequence = setup_sequence

    sub1 = ODDB::Drugs::Substance.new
    sub1.name.de = 'Enalapril'
    sub1.save

    user = login_admin
    uid = sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"

    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title
    assert is_element_present("link=+")
    assert is_element_present("link=-")

    click "link=+"
    assert is_text_present("(unsaved)")
    sleep(0.5)
    assert !is_element_present("link=+")
    assert is_element_present("link=-")
    assert is_element_present("substance[0][1]")
    assert is_element_present("dose[0][1]")
    refresh
    wait_for_page_to_load "30000"

    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title
    assert is_element_present("link=+")
    assert is_element_present("link=-")
    assert !is_element_present("substance[0][1]")
    assert !is_element_present("dose[0][1]")

    click "link=+"
    assert is_text_present("(unsaved)")
    sleep(0.5)
    type "substance[0][1]", "Enalapril"
    type "dose[0][1]", "50 mg"

    click "update"
    wait_for_page_to_load "30000"
    assert !is_text_present("(unsaved)")

    assert_equal 1, sequence.compositions.size
    composition = sequence.compositions.first
    assert_equal 2, composition.active_agents.size
    agent = composition.active_agents.last
    assert_equal sub1, agent.substance
    assert_equal ODDB::Drugs::Dose.new(50, 'mg'), agent.dose

    assert is_element_present("link=+")
    assert is_element_present("link=-")
    assert is_element_present("substance[0][1]")
    assert is_element_present("dose[0][1]")
    assert_equal "Enalapril", get_value("substance[0][1]")
    assert_equal "50 mg", get_value("dose[0][1]")

    click "link=+"
    sleep(0.5)
    assert is_element_present("substance[0][2]")
    click "//table[@id='active-agents-0']//tr[3]//td[1]//a"
    sleep(0.5)
    assert is_element_present("link=+")
    assert !is_element_present("substance[0][2]")
 
    click "//table[@id='active-agents-0']//tr[2]//td[1]//a"
    sleep(0.5)
    assert !is_element_present("substance[0][1]")
    assert_equal 1, composition.active_agents.size
  end
  def test_sequence__compositions
    sequence = setup_sequence

    sub1 = ODDB::Drugs::Substance.new
    sub1.name.de = 'Enalapril'
    sub1.save

    user = login_admin
    uid = sequence.uid
    open "/de/drugs/sequence/uid/#{uid}"

    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title
    assert is_element_present("link=Bestandteil hinzufügen")
    assert is_element_present("link=Bestandteil löschen")

    click "link=Bestandteil hinzufügen"
    sleep(0.5)
    assert is_text_present("(unsaved)")
    assert !is_element_present("link=Bestandteil hinzufügen")
    assert is_element_present("link=Bestandteil löschen")
    assert is_element_present("substance[1][0]")
    assert is_element_present("dose[1][0]")
    refresh
    wait_for_page_to_load "30000"

    assert_equal "DE - ODDB.org | Medikamente | Sequenz | #{uid} | Open Drug Database", get_title
    assert is_element_present("link=Bestandteil hinzufügen")
    assert is_element_present("link=Bestandteil löschen")
    assert !is_element_present("substance[1][0]")
    assert !is_element_present("dose[1][0]")

    click "link=Bestandteil hinzufügen"
    sleep(0.5)
    assert is_text_present("(unsaved)")
    type "substance[1][0]", "Enalapril"
    type "dose[1][0]", "50 mg"

    click "update"
    wait_for_page_to_load "30000"

    assert !is_text_present("(unsaved)")
    assert_equal 2, sequence.compositions.size
    composition = sequence.compositions.last
    assert_equal 1, composition.active_agents.size
    agent = composition.active_agents.last
    assert_equal sub1, agent.substance
    assert_equal ODDB::Drugs::Dose.new(50, 'mg'), agent.dose

    assert is_element_present("link=Bestandteil hinzufügen")
    assert is_element_present("link=Bestandteil löschen")
    assert is_element_present("substance[1][0]")
    assert is_element_present("dose[1][0]")
    assert_equal "Enalapril", get_value("substance[1][0]")
    assert_equal "50 mg", get_value("dose[1][0]")

    click "//table[@id='active-agents-1']//a[text()='Bestandteil löschen']"
    sleep(0.5)
    assert !is_element_present("substance[1][0]")
    assert_equal 1, composition.active_agents.size
  end
  def test_new_sequence__success
    sequence = setup_sequence
    user = login_admin
    product = sequence.product
    uid = product.uid
    open "/de/drugs/product/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title

    click "new_sequence"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Neue Sequenz | Open Drug Database", get_title

    atc = Drugs::Atc.new('A01AA01')
    atc.name.de = "Assigned Atc-Class"
    atc.save

    type 'registration', '54321.5'
    type 'atc', 'A01AA01'

    fachinfo = "A Fachinfo-Document"
    fi_url = "http://host.domain/fi_path.rtf"
    type "fi_url", fi_url
    patinfo = "A Patinfo-Document"
    pi_url = "http://host.domain/pi_path.rtf"
    type "pi_url", pi_url

    flexmock(Import::PharmNet::Import).new_instances\
      .should_receive(:import_rtf).and_return { |key, agent, url, term|
      assert_instance_of WWW::Mechanize, agent
      assert_equal 'Product', term
      case key
      when :fachinfo
        assert_equal fi_url, url
        fachinfo
      when :patinfo
        assert_equal pi_url, url
        patinfo
      else
        flunk "import_rtf was called with invalid key: #{key.inspect}"
      end
    }

    click "//input[@name='update']"
    wait_for_page_to_load "30000"

    assert !is_text_present('Der ATC-Code "A01AA01" ist nicht bekannt.')
    assert !is_text_present("Die EU-Registrationsnummer '54321.5' (Product) ist bereits vergeben.")

    assert_equal 'A01AA01', get_value('atc')
    assert is_text_present('Assigned Atc-Class')
    assert_equal '54321.5', get_value('registration')
    assert is_text_present("FI")
    assert is_text_present("GI")

    assert_equal(2, product.sequences.size)
    sequence = product.sequences.last
    
    assert_equal(atc, sequence.atc)
    assert_equal('54321.5', sequence.code(:registration, 'EU').value)
    assert_equal(fachinfo, sequence.fachinfo.de)
    assert_equal(patinfo, sequence.patinfo.de)

    [:atc, :fi_url, :pi_url, :registration].each { |key|
      assert_equal 'test.admin@oddb.org', sequence.data_origin(key)
    }

  end
  def test_new_sequence__errors
    sequence = setup_sequence
    user = login_admin
    product = sequence.product
    uid = product.uid
    open "/de/drugs/product/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title

    click "new_sequence"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Neue Sequenz | Open Drug Database", get_title
    assert !is_element_present('new_package')

    type 'registration', '12345.0'
    type 'atc', 'A01AA01'

    click "//input[@name='update']"
    wait_for_page_to_load "30000"

    #assert is_text_present('Der ATC-Code "A01AA01" ist nicht bekannt.')
    assert is_text_present("Die EU-Registrationsnummer '12345.0' (Product) ist bereits vergeben.")

    assert_equal 'A01AA01', get_value('atc')
    assert_equal '12345.0', get_value('registration')

    assert_equal(1, product.sequences.size)
  end
  def test_new_sequence__delete
    sequence = setup_sequence
    user = login_admin
    uid = sequence.product.uid
    open "/de/drugs/product/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title

    click "new_sequence"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Neue Sequenz | Open Drug Database", get_title

    click "delete"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title

    assert_equal 1, sequence.product.sequences.size
  end
end
  end
end
