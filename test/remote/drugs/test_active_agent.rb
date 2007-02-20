#!/usr/bin/env ruby
# Remote::Drugs::TestActiveAgent -- de.oddb.org -- 20.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/active_agent'
require 'oddb/drugs/substance'
require 'oddb/remote/drugs/active_agent'
require 'flexmock'

module ODDB
  module Remote
    module Drugs
class TestActiveAgent < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @remote = flexmock('Remote')
    rsub = flexmock('Substance')
    rsub.should_receive(:de).and_return('Substance')
    @remote.should_receive(:substance).and_return(rsub)
    @active_agent = ActiveAgent.new(0, @remote)
  end
  def test_spaceship__no_dose
    sub = ODDB::Drugs::Substance.new
    sub.name.de = 'Substance'
    local = ODDB::Drugs::ActiveAgent.new(sub, 10)
    @remote.should_receive(:dose).and_return(nil)
    assert_nothing_raised {
      @active_agent <=> local
    }
  end
end
    end
  end
end
