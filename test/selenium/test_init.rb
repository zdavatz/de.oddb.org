#!/usr/bin/env ruby
# Selenium::TestInit -- de.oddb.org -- 20.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/util'

module ODDB
  module Selenium
class TestInit < Test::Unit::TestCase
  include Selenium::TestCase
  def test_init
    @selenium.open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", @selenium.get_title
    assert @selenium.is_element_present("query")
    assert @selenium.is_element_present("reset")
    assert @selenium.is_element_present("//input[@name='search']")
    assert_match Regexp.new(ODDB.config.http_server), 
      @selenium.get_attribute("//form[@name='search']@action")
    assert @selenium.is_element_present("link=Home")
    assert @selenium.is_element_present("link=Kontakt")
    assert @selenium.is_element_present("link=Arzneimittel A-Z")
  end
  def test_init__mm
    @selenium.open "/de/drugs/home/flavor/mm"
    assert_equal "CH | DE - ODDB.org | Medikamente | Home | Open Drug Database", @selenium.get_title
    assert @selenium.is_element_present("query")
    assert @selenium.is_element_present("reset")
    assert @selenium.is_element_present("//input[@name='search']")
    assert_match Regexp.new(ODDB.config.http_server), 
      @selenium.get_attribute("//form[@name='search']@action")
    assert @selenium.is_element_present("link=Home")
    assert @selenium.is_element_present("link=Kontakt")
    assert @selenium.is_element_present("link=Arzneimittel A-Z")
  end
end
  end
end
