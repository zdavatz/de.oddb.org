#!/usr/bin/env ruby
# Drugs::TestSequence -- de.oddb.org -- 10.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/sequence'

module ODDB
  module Drugs
    class TestSequence < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @sequence = Sequence.new
      end
      def test_include
        sub1 = flexmock('substance')
        sub2 = flexmock('substance')
        assert_equal(false, @sequence.include?(sub1, 10, 'mg'))
        assert_equal(false, @sequence.include?(sub2, 10, 'mg'))
        comp = flexmock('composition')
        @sequence.add_composition(comp)
        comp.should_receive(:include?).and_return { |sub, dose, unit|
          assert_equal(10, dose)
          assert_equal('mg', unit)
          sub == sub1
        }
        assert_equal(true, @sequence.include?(sub1, 10, 'mg'))
        assert_equal(false, @sequence.include?(sub2, 10, 'mg'))
      end
    end
  end
end
