#!/usr/bin/env ruby
# Util::TestYus -- de.oddb.org -- 01.02.2008 -- hwyss@ywesee.com


$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/config'
require 'oddb/util/yus'

module ODDB
  module Util
class TestYus < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @yus = flexmock('yus')
    @remote = DRb.start_service('druby://localhost:0', @yus)
    ODDB.config.auth_server = @remote.uri
    ODDB.server = flexmock('server')
    @session = setup_autosession
    super
  end
  def teardown
    @remote.stop_service
    super
  end
  def setup_autosession
    session = flexmock('session')
    @yus.should_receive(:autosession).and_return {  |domain, block|
      assert_equal 'org.oddb.de', domain
      block.call session
    }
    session
  end
  def test_create_user
    @session.should_receive(:create_entity).with('test@email.com', 'password')
    ODDB.server.should_receive(:login).with('test@email.com', 'password')
    Yus.create_user('test@email.com', 'password')
  end
  def test_get_preference
    @session.should_receive(:get_entity_preference)\
      .with('test@email.com', :name_last).and_return 'Test'
    assert_equal 'Test', Yus.get_preference('test@email.com', :name_last)
  end
  def test_get_preference__fails
    @session.should_receive(:get_entity_preference).and_return {
      raise ::Yus::YusError
    }
    assert_nil Yus.get_preference('test@email.com', :name_last)
  end
  def test_get_preferences
    expected = {
      :name_first => 'Fritz',
      :name_last => 'Test',
    }
    @session.should_receive(:get_entity_preferences)\
      .with('test@email.com', [:name_last, :name_first]).and_return expected
    assert_equal expected,
      Yus.get_preferences('test@email.com', :name_last, :name_first)
  end
  def test_get_preferences__fails
    @session.should_receive(:get_entity_preferences).and_return {
      raise ::Yus::YusError
    }
    assert_equal({}, Yus.get_preferences('test@email.com', :name_last))
  end
  def test_grant
    @session.should_receive(:grant).with('test@email.com', 'view', 'de.oddb.org', nil)
    Yus.grant('test@email.com', 'view', 'de.oddb.org')
  end
  def test_set_preference
    @session.should_receive(:set_entity_preference)\
      .with('test@email.com', :name_last, 'Test', 'org.oddb.de')
    Yus.set_preference('test@email.com', :name_last, 'Test', 'org.oddb.de')
  end
end
  end
end
