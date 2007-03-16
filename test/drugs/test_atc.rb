#!/usr/bin/env ruby
# Drugs::TestAtc -- de.oddb.org -- 20.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/atc'
require 'test/stub/model'

module ODDB
  module Drugs
    class TestAtc < Test::Unit::TestCase
      def setup
        @atc = Atc.new('A01AA01')
      end
      def test_level
        l1 = Atc.new('A')
        assert_equal(1, l1.level)
        l2 = Atc.new('A01')
        assert_equal(2, l2.level)
        l3 = Atc.new('A01A')
        assert_equal(3, l3.level)
        l4 = Atc.new('A01AA')
        assert_equal(4, l4.level)
        assert_equal(5, @atc.level)
      end
      def test_parent
        @atc.save
        parent = Atc.new('A01AA')
        parent.save
        grandparent = Atc.new('A01A')
        grandparent.save
        assert_equal(parent, @atc.parent)
        assert_equal(grandparent, parent.parent)
        assert_nil(grandparent.parent)
      end
      def test_parent_code
        assert_equal('A01AA', @atc.parent_code)
        l4 = Atc.new('A01AA')
        assert_equal('A01A', l4.parent_code)
        l3 = Atc.new('A01A')
        assert_equal('A01', l3.parent_code)
        l2 = Atc.new('A01')
        assert_equal('A', l2.parent_code)
        l1 = Atc.new('A')
        assert_equal(nil, l1.parent_code)
      end
      def test_sort
        other = Atc.new('B01BC02')
        assert_equal([@atc, other], [other, @atc].sort)
      end
    end
  end
end
