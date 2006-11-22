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
    end
  end
end
