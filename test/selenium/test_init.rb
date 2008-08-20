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
  def setup
    f1 = Util::Feedback.new
    i1 = flexmock('package')
    p1 = flexmock('part')
    p1.should_receive(:size).and_return(10)
    u1 = Drugs::Unit.new
    u1.name.de = 'Tabletten'
    p1.should_receive(:unit).and_return(u1)
    p1.should_ignore_missing
    i1.should_receive(:name).and_return('Product')
    i1.should_receive(:parts).and_return [p1]
    i1.should_ignore_missing
    f1.item = i1
    f1.save
    super
  end
  def teardown
    Util::Feedback.instances.clear
    super
  end
  def test_init
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    assert is_element_present("query")
    assert is_element_present("reset")
    assert is_element_present("//input[@name='search']")
    assert_match Regexp.new(ODDB.config.http_server), 
      get_attribute("//form[@name='search']@action")
    assert is_element_present("link=Home")
    assert is_element_present("link=Kontakt")
    assert is_element_present("link=Arzneimittel A-Z")
    assert is_element_present("//a[@name='feedback_feed_title']")
    assert is_text_present("Product in der Handelsform: 10 Tabletten")
  end
  def test_init__mm
    open "/de/drugs/home/flavor/mm"
    assert_equal "CH | DE - ODDB.org | Medikamente | Home | Open Drug Database", get_title
    assert is_element_present("query")
    assert is_element_present("reset")
    assert is_element_present("//input[@name='search']")
    assert_match Regexp.new(ODDB.config.http_server), 
      get_attribute("//form[@name='search']@action")
    assert is_element_present("link=Home")
    assert is_element_present("link=Kontakt")
    assert is_element_present("link=Arzneimittel A-Z")
    assert !is_element_present("//a[@name='feedback_feed_title']")
    assert !is_text_present("in der Handelsform")
  end
end
  end
end
