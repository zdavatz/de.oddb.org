#!/usr/bin/env ruby
# Selenium::TestCase -- de.oddb.org -- 21.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

ENV['LD_LIBRARY_PATH'] = '/usr/local/firefox'

$log_level = 0

if(pid = Kernel.fork)
  at_exit {
    Process.kill('HUP', pid)
    $selenium.stop if($log_level == 0 && $selenium.respond_to?(:stop))
  }
else
  path = File.expand_path('selenium-server.jar', File.dirname(__FILE__))
  command = $log_level > 0 ? "java -jar #{path}" : "java -jar #{path} &> /dev/null"
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
    Drugs::Atc.instances.clear
    Drugs::Product.instances.clear
    Drugs::Sequence.instances.clear
    Drugs::Package.instances.clear
    Business::Company.instances.clear
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
    @http_server = Stub.http_server(drb_url, $log_level)
    @webrick = Thread.new { @http_server.start }
    @verification_errors = []
    if $selenium
      @selenium = $selenium
    else
      @selenium = SeleniumWrapper.new("localhost", 4444, "*chrome",
        ODDB.config.http_server + ":10080", 10000)
      @selenium.start
    end
    @selenium.set_context("info")
    ODDB::Html::Util::Session.reset_query_limit
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
    click "//input[@name='login_']"
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
    user.should_receive(:permissions).and_return(permissions)
    user.should_ignore_missing
    user
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
end
  end
end
