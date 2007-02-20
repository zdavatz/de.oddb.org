#!/usr/bin/env ruby
# Selenium::TestInit -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com


$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Selenium
class TestProducts < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::Product.instances.clear
    super
  end
  def setup_product(name)
    product = Drugs::Product.new
    sequence = Drugs::Sequence.new
    sequence.product = product
    sequence.atc = Drugs::Atc.new('N04BB01')
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    product.name.de = name
    product.save
  end
  def test_products
    setup_product("Amantadin by Producer")
    setup_product("Amantadin by someone Else")
    setup_product("4N Pflaster")
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    @selenium.click "link=Arzneimittel A-Z"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    assert @selenium.is_text_present("Bitte wählen Sie den anzuzeigenden Bereich")
    assert @selenium.is_element_present("link=A")
    assert @selenium.is_element_present("link=0-9")

    @selenium.click "link=A"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert @selenium.is_text_present('Amantadin by someone Else')
    assert !@selenium.is_text_present('4N Pflaster')
    assert @selenium.is_text_present('Producer AG')
    assert @selenium.is_text_present('N04BB01')

    flexstub(@server['test:preset-session-id']).should_receive(:pagelength).and_return(1)

    @selenium.refresh
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert !@selenium.is_text_present('Amantadin by someone Else')
    assert !@selenium.is_text_present('4N Pflaster')
    assert @selenium.is_text_present('1 - 1')
    assert @selenium.is_text_present('2 - 2')
    assert !@selenium.is_text_present('3 - 2')

    @selenium.click "link=2 - 2"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    assert !@selenium.is_text_present('Amantadin by Producer')
    assert @selenium.is_text_present('Amantadin by someone Else')
    assert !@selenium.is_text_present('4N Pflaster')
    assert @selenium.is_text_present('1 - 1')
    assert @selenium.is_text_present('2 - 2')
    assert !@selenium.is_text_present('3 - 2')

    @selenium.click "link=0-9"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    assert !@selenium.is_text_present('Amantadin by Producer')
    assert !@selenium.is_text_present('Amantadin by someone Else')
    assert @selenium.is_text_present('4N Pflaster')

    @selenium.click "link=4N Pflaster"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Suchen | 4N Pflaster", 
                 @selenium.get_title
  end
  def test_products__sort
    setup_product("Amantadin by Producer")
    setup_product("Amantadin by someone Else")
    setup_product("4N Pflaster")
    @selenium.open "/"
    assert_equal "ODDB | Medikamente | Home", @selenium.get_title
    @selenium.click "link=Arzneimittel A-Z"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    assert @selenium.is_text_present("Bitte wählen Sie den anzuzeigenden Bereich")
    assert @selenium.is_element_present("link=A")
    assert @selenium.is_element_present("link=0-9")

    @selenium.click "link=A"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    assert @selenium.is_text_present('Amantadin by Producer')
    assert @selenium.is_text_present('Amantadin by someone Else')

    @selenium.click "link=ATC-Code"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
    @selenium.click "link=Hersteller"
    @selenium.wait_for_page_to_load "30000"
    assert_equal "ODDB | Medikamente | Arzneimittel A-Z", 
                 @selenium.get_title
  end
end
  end
end
