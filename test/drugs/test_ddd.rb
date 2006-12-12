#!/usr/bin/env ruby
# Drugs::TestDdd -- de.oddb.org -- 12.12.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/ddd'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
    class TestDdd < Test::Unit::TestCase
      def test_to_s
        ddd = Ddd.new('o')
        ddd.dose = Dose.new(12, 'mg')
        assert_equal('o: 12 mg', ddd.to_s)
        ddd.comment = 'a comment'
        assert_equal('o: 12 mg (a comment)', ddd.to_s)
      end
    end
  end
end
