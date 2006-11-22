#!/usr/bin/env ruby
# Drugs::TestPackage -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/package'

module ODDB
  module Drugs
    class TestPackage < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @package = Package.new
      end
      def test_size
        assert_equal(0, @package.size)
        part1 = flexmock("part")
        part1.should_receive(:size).and_return(1)
        @package.add_part(part1)
        assert_equal(1, @package.size)
        part2 = flexmock("part")
        part2.should_receive(:size).and_return(2)
        @package.add_part(part2)
        assert_equal(3, @package.size)
      end
    end
  end
end
