#!/usr/bin/env ruby
# Selenium::TestProduct -- de.oddb.org -- 18.04.2008 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Selenium
class TestAdminProduct < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::ActiveAgent.instances.clear
    Drugs::Composition.instances.clear
    Drugs::Sequence.instances.clear
    Drugs::Product.instances.clear
    Business::Company.instances.clear
    super
  end
  def setup_product
    product = Drugs::Product.new
    product.name.de = "Product"
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    product.save
    product
  end
  def test_product
    product = setup_product
    user = login_admin
    uid = product.uid
    open "/de/drugs/product/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title
    assert is_element_present("company")
    assert is_text_present("Product")
    assert_equal 'Producer AG', get_value('company')
  end
  def test_product__update__success
    product = setup_product
    user = login_admin
    company = Business::Company.new
    company.name.de = 'New Company'
    company.save
    uid = product.uid
    open "/de/drugs/product/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title
    type 'company', 'New Company'
    click 'update'
    wait_for_page_to_load "30000"

    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title
    assert_equal 'New Company', get_value('company')

    assert_equal company, product.company
  end
  def test_product__update__error
    product = setup_product
    previous = product.company
    user = login_admin
    uid = product.uid
    open "/de/drugs/product/uid/#{uid}"
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title
    type 'company', 'New Company'
    click 'update'
    wait_for_page_to_load "30000"

    assert is_text_present('Der Zulassungsinhaber "New Company" ist nicht bekannt.')
    assert_equal "DE - ODDB.org | Medikamente | Produkt | #{uid} | Open Drug Database", get_title
    assert_equal 'Producer AG', get_value('company')

    assert_equal previous, product.company
  end
end
  end
end
