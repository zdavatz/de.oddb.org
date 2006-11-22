#!/usr/bin/env ruby
# Drugs::TestComposition -- de.oddb.org -- 10.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/composition'

module ODDB
  module Drugs
    class TestComposition < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @composition = Composition.new
      end
      def test_include
        sub1 = flexmock('substance')
        sub2 = flexmock('substance')
        assert_equal(false, @composition.include?(sub1, 10, 'mg'))
        assert_equal(false, @composition.include?(sub2, 10, 'mg'))
        act = flexmock('active_agent')
        @composition.add_active_agent(act)
        act.should_receive(:substance).and_return(sub1)
        act.should_receive(:dose).and_return(Dose.new(10, 'mg'))
        assert_equal(true, @composition.include?(sub1, 10, 'mg'))
        assert_equal(false, @composition.include?(sub2, 10, 'mg'))
      end
      def test_active_agent
        agt1 = flexmock('agent')
        agt2 = flexmock('agent')
        agt1.should_receive(:substance).and_return("substance1")
        agt2.should_receive(:substance).and_return("substance2")
        @composition.add_active_agent(agt1)
        @composition.add_active_agent(agt2)
        assert_equal(agt1, @composition.active_agent("substance1"))
        assert_equal(agt2, @composition.active_agent("substance2"))
      end
    end
  end
end
