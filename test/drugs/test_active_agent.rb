#!/usr/bin/env ruby
# Drugs::TestActiveAgent -- de.oddb.org -- 22.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/active_agent'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
    class TestActiveAgent < Test::Unit::TestCase
      include FlexMock::TestCase
      def test_create
        substance = flexmock('substance')
        dose = Dose.new(100, 'mg')
        agent = ActiveAgent.new(substance, dose)
        assert_equal(dose, agent.dose)
        agent = ActiveAgent.new(substance, 100, 'mg')
        assert_equal(dose, agent.dose)
      end
      def test_equality
        substance = flexmock('substance')
        dose = Dose.new(100, 'mg')
        agent = ActiveAgent.new(substance, dose)
        equal = ActiveAgent.new(substance, dose)
        assert_equal(true, agent == equal)
        assert_equal(true, equal == agent)

        other = ActiveAgent.new(substance, Dose.new(200, 'mg'))
        assert_equal(false, other == agent)
        assert_equal(false, agent == other)
        
        substance = flexmock('different substance')
        other = ActiveAgent.new(substance, dose)
        assert_equal(false, other == agent)
        assert_equal(false, agent == other)

        other.chemical_equivalence = equal
        assert_equal(true, other == agent)
        assert_equal(true, agent == other)
      end
      def test_equality__nil
        substance = flexmock('substance')
        dose = Dose.new(100, 'mg')
        agent = ActiveAgent.new(substance, dose)

        assert_equal(false, agent == nil)
      end
    end
  end
end
