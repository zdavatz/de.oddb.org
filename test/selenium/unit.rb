#!/usr/bin/env ruby
# Selenium::TestCase -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

if(pid = Kernel.fork)
  at_exit {
    Process.kill('HUP', pid)
    $selenium.stop if($selenium.respond_to?(:stop))
  }
else
  path = File.expand_path('selenium-server.jar', File.dirname(__FILE__))
  command = "java -jar #{path} &> /dev/null"
  exec(command) 
end

require "oddb/config"
require 'delegate'
require 'selenium'

module ODDB
  module Selenium
class SeleniumWrapper < SimpleDelegator
  def initialize(host, port, browser, server, port2)
    @server = server
    @selenium = ::Selenium::SeleneseInterpreter.new(host, port, browser,
                                                    server, port2)
    super @selenium
  end
  def open(path)
    @selenium.open(@server + path)
  end
  def type(*args)
    @selenium.type(*args)
  end
end
  end
end

$selenium = ODDB::Selenium::SeleniumWrapper.new("localhost", 4444, 
  "*chrome", ODDB.config.http_server + ":10080", 10000)

start = Time.now
begin
  $selenium.start
rescue Errno::ECONNREFUSED
  sleep 1
  if((Time.now - start) > 15)
    raise
  else
    retry
  end
end

require "oddb/util/server"
require 'flexmock'
require 'logger'
require 'stub/http_server'
require "test/unit"

module ODDB
  module Selenium
module TestCase
  include FlexMock::TestCase
  include SeleniumHelper
  def setup
    ODDB.logger = Logger.new($stdout)
    ODDB.logger.level = Logger::DEBUG
    @auth = flexmock('authenticator')
    ODDB.auth = @auth
    @persistence = flexmock('persistence')
    ODDB.persistence = @persistence
    @server = Util::Server.new(@persistence)
    @server.extend(DRbUndumped)
    drb_url = "druby://localhost:10081"
    @drb = Thread.new { 
      @drb_server = DRb.start_service(drb_url, @server) 
    }
    @drb.abort_on_exception = true
    @http_server = Stub.http_server(drb_url)
    @webrick = Thread.new { @http_server.start }
    @verification_errors = []
    if $selenium
      @selenium = $selenium
    else
      @selenium = SeleniumWrapper.new("localhost", 4444, "*chrome",
        ODDB.config.http_server + ":10080", 10000)
      @selenium.start
    end
    @selenium.set_context("TestOddb", "info")
  end
  def teardown
    @selenium.stop unless $selenium
    @http_server.shutdown
    @drb_server.stop_service
    assert_equal [], @verification_errors
    super
  end
  def login(email, *permissions)
    user = mock_user email, *permissions
    @auth.should_receive(:login).and_return(user)
    open "/de/drugs/login"
    type "email", email
    type "pass", "test"
    click "//input[@name='login']"
    wait_for_page_to_load "30000"
    user
  end
  def login_admin
    login "test.admin@oddb.org", ['login', 'org.oddb.de.Admin']
  end
  def mock_user(email, *permissions)
    user = flexmock(email)
    user.should_receive(:allowed?).and_return { |*pair|
      permissions.include?(pair)
    }
    user.should_receive(:name).and_return(email)
    user.should_receive(:get_preference)
    user.should_receive(:find_entity).and_return { |email|
      (@yus_entities ||= {})[email]
    }
    user.should_receive(:last_login)
    user.should_ignore_missing
    user
  end
end
  end
end
