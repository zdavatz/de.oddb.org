#!/usr/bin/env ruby
# Drugs::TestSequence -- de.oddb.org -- 10.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/ddd'
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
        seq1 = Sequence.new
        seq2 = Sequence.new
        atc = flexmock('atc')
        atc.should_receive(:sequences)\
          .and_return([seq1, @sequence, seq2])
        atc.should_ignore_missing
        @sequence.atc = atc

        comp1 = flexmock('composition')
        @sequence.add_composition(comp1)
        seq1.add_composition(comp1)
        comp2 = flexmock('composition')
        seq2.add_composition(comp2)

        assert_equal([seq1, @sequence], @sequence.comparables)
      end
      def test_ddds
        ddd1 = Drugs::Ddd.new('O')
        ddd2 = Drugs::Ddd.new('P')
        atc = flexmock('atc')
        atc.should_ignore_missing
        atc.should_receive(:ddds).and_return([ddd1, ddd2])
        @sequence.atc = atc

        comp1 = flexmock('composition')
        comp1.should_ignore_missing
        @sequence.add_composition(comp1)
        assert_equal([], @sequence.ddds)

        form1 = flexmock('galenic_form')
        form1.should_ignore_missing
        comp1.should_receive(:galenic_form).and_return(form1)
        assert_equal([], @sequence.ddds)

        group1 = flexmock('galenic_group')
        group1.should_ignore_missing
        form1.should_receive(:group).and_return(group1)
        assert_equal([], @sequence.ddds)

        group1.should_receive(:administration).and_return('O')
        assert_equal([ddd1], @sequence.ddds)
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
