#!/usr/bin/env ruby
# Drugs::TestPart -- de.oddb.org -- 22.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/part'

module ODDB
  module Drugs
    class TestPart < Test::Unit::TestCase
      def setup
        @part = Part.new
      end
      def test_size_writer
        @part.size = 1.5
        assert_instance_of(Float, @part.size)
        assert_equal(1.5, @part.size)
        @part.size = 5
        assert_instance_of(Fixnum, @part.size)
        assert_equal(5, @part.size)
      end
      def test_comparable_size
        assert_equal(Dose.new(1), @part.comparable_size)
        @part.size = "4.5"
        assert_equal(Dose.new(4.5), @part.comparable_size)
        @part.quantity = Dose.new(20, 'ml')
        assert_equal(Dose.new(90, 'ml'), @part.comparable_size)
      end
    end
  end
end
