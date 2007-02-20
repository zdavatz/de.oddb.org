#!/usr/bin/env ruby
# Drugs::TestAtc -- de.oddb.org -- 20.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/atc'

module ODDB
  module Drugs
    class TestAtc < Test::Unit::TestCase
      def setup
        @atc = Atc.new('A01AA01')
      end
      def test_sort
        other = Atc.new('B01BC02')
        assert_equal([@atc, other], [other, @atc].sort)
      end
    end
  end
end
