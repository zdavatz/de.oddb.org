#!/usr/bin/env ruby
# Drugs::TestSubstanceGroup -- de.oddb.org -- 13.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/substance_group'

module ODDB
  module Drugs
    class TestSubstanceGroup < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @group = SubstanceGroup.new
      end
      def test_add_substance
        assert_equal([], @group.substances)
        sub = flexmock('substance')
        @group.add_substance(sub)
        assert_equal([sub], @group.substances)
        @group.add_substance(sub)
        assert_equal([sub], @group.substances)
      end
    end
  end
end
