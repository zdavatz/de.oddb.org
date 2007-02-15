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
      def test_comparable
        other = Sequence.new
        third = Sequence.new
        assert_equal(true, @sequence.comparable?(other))
        assert_equal(true, other.comparable?(@sequence))
        assert_equal(true, @sequence.comparable?(third))
        assert_equal(true, third.comparable?(@sequence))

        comp1 = flexmock('composition')
        @sequence.add_composition(comp1)
        assert_equal(false, @sequence.comparable?(other))
        assert_equal(false, other.comparable?(@sequence))

        other.add_composition(comp1)
        assert_equal(true, @sequence.comparable?(other))
        assert_equal(true, other.comparable?(@sequence))

        comp2 = flexmock('other composition')
        third.add_composition(comp2)
        assert_equal(false, @sequence.comparable?(third))
        assert_equal(false, third.comparable?(@sequence))

        @sequence.add_composition(comp2)
        other.add_composition(comp2)
        third.add_composition(comp1)
        assert_equal(true, @sequence.comparable?(other))
        assert_equal(true, other.comparable?(@sequence))
        assert_equal(false, @sequence.comparable?(third))
        assert_equal(false, third.comparable?(@sequence))
      end
      def test_comparables
        prod1 = flexmock('product')
        prod2 = flexmock('product')

        seq1 = Sequence.new
        prod1.should_receive(:sequences).and_return([seq1])
        seq2 = Sequence.new
        prod2.should_receive(:sequences).and_return([seq2])

        comp1 = flexmock('composition')
        @sequence.add_composition(comp1)
        seq1.add_composition(comp1)
        comp2 = flexmock('composition')
        seq2.add_composition(comp2)

        product = flexmock('product')
        product.should_receive(:comparables).and_return([prod1, prod2])
        product.should_ignore_missing

        @sequence.product = product

        assert_equal([seq1], @sequence.comparables)
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
