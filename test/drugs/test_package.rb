#!/usr/bin/env ruby
# Drugs::TestPackage -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/package'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
    class TestPackage < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @package = Package.new
      end
      def test_comparable
        other = Package.new
        third = Package.new

        ## empty packages are comparable
        assert_equal(true, other.comparable?(@package))
        assert_equal(true, @package.comparable?(other))
        assert_equal(true, third.comparable?(@package))
        assert_equal(true, @package.comparable?(third))

        ## if the number of parts is different: not comparable
        part1 = flexmock("part")
        part1.should_receive(:comparable_size)\
          .and_return(Dose.new(10, 'mg'))
        @package.add_part(part1)
        assert_equal(false, other.comparable?(@package))
        assert_equal(false, @package.comparable?(other))
        assert_equal(false, third.comparable?(@package))
        assert_equal(false, @package.comparable?(third))

        ## if the comparable_size is the same: comparable
        part2 = flexmock("part")
        part2.should_receive(:comparable_size)\
          .and_return(Dose.new(10, 'mg'))
        other.add_part(part2)
        assert_equal(true, other.comparable?(@package))
        assert_equal(true, @package.comparable?(other))

        ## if the comparable_size is not the same: not comparable
        part3 = flexmock("part")
        part3.should_receive(:comparable_size)\
          .and_return(Dose.new(20, 'mg'))
        third.add_part(part3)
        assert_equal(false, third.comparable?(@package))
        assert_equal(false, @package.comparable?(third))

        ## comparable still works for multiple parts
        @package.add_part(part3)
        other.add_part(part3)
        assert_equal(true, other.comparable?(@package))
        assert_equal(true, @package.comparable?(other))

        ## ... but not if the order of parts is different
        third.add_part(part2)
        assert_equal(false, third.comparable?(@package))
        assert_equal(false, @package.comparable?(third))
      end
      def test_comparables
        part1 = flexmock("part")
        part1.should_receive(:comparable_size)\
          .and_return(Dose.new(10, 'mg'))
        @package.add_part(part1)

        sequence = flexmock('sequence')
        seq1 = flexmock('sequence')
        seq2 = flexmock('sequence')
        sequence.should_receive(:comparables).and_return([seq1, seq2])
        sequence.should_ignore_missing
        @package.sequence = sequence

        package1 = Package.new
        package1.add_part(part1)
        seq1.should_receive(:packages).and_return([package1, @package])

        part2 = flexmock("part")
        part2.should_receive(:comparable_size)\
          .and_return(Dose.new(20, 'mg'))
        package2 = Package.new
        package2.add_part(part2)
        seq2.should_receive(:packages).and_return([package2])

        assert_equal([package1], @package.comparables)
      end
      def test_comparable_size
        assert_equal([], @package.comparable_size)
        part1 = flexmock("part")
        part1.should_receive(:comparable_size)\
          .and_return(Dose.new(10, 'mg'))
        @package.add_part(part1)
        assert_equal([Dose.new(10, 'mg')], @package.comparable_size)
        part2 = flexmock("part")
        part2.should_receive(:comparable_size)\
          .and_return(Dose.new(20, 'mg'))
        @package.add_part(part2)
        assert_equal([Dose.new(10, 'mg'), Dose.new(20, 'mg')], 
                     @package.comparable_size)
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
