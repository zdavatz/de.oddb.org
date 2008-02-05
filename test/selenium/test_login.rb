#!/usr/bin/env ruby
# Selenium::TestLogin -- de.oddb.org -- 23.01.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/config'

module ODDB
  module Selenium
class TestLogin < Test::Unit::TestCase
  include Selenium::TestCase
  def test_login
    open "/"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", @selenium.get_title
    click "link=Anmelden"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Anmelden | Open Drug Database", @selenium.get_title
    assert_equal "E-Mail", get_text("//label[@for='email']")
    assert is_element_present("email")
    assert_equal "Passwort", get_text("//label[@for='pass']")
    assert is_element_present("pass")
    assert_match Regexp.new(ODDB.config.http_server), 
      get_attribute("//form[@name='login']@action")
    assert is_element_present("//input[@name='login_']")
  end
  def test_login__fail_unknown_user
    open "/"
    click "link=Anmelden"
    wait_for_page_to_load "30000"
    @auth.should_receive(:login).and_return { raise Yus::UnknownEntityError }
    type "email", "unknown@bbmb.ch"
    type "pass", "secret"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Anmelden | Open Drug Database", @selenium.get_title
    assert_equal "error", get_attribute("//label[@for='email']@class")
  end
  def test_login__fail_wrong_password
    open "/"
    click "link=Anmelden"
    wait_for_page_to_load "30000"
    @auth.should_receive(:login).and_return { raise Yus::AuthenticationError }
    type "email", "unknown@bbmb.ch"
    type "pass", "secret"
    click "//input[@type='submit']"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Anmelden | Open Drug Database", @selenium.get_title
    assert_equal "error", get_attribute("//label[@for='pass']@class")
  end
  def test_login__success
    user = login_admin
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", @selenium.get_title
  end
  def test_logout
    user = login_admin
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", @selenium.get_title
    @auth.should_receive(:logout).and_return { assert true }
    click "link=Abmelden"
    wait_for_page_to_load "30000"
    assert_equal "DE - ODDB.org | Medikamente | Home | Open Drug Database", @selenium.get_title
    assert !is_text_present('Abmelden')
  end
end
  end
end
