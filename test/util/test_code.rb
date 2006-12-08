#!/usr/bin/env ruby
# Util::TestCode -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com


$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/util/code'

module ODDB
  module Util
    class TestCode < Test::Unit::TestCase
      def test_registration_ch
        code = Code.new(:registration, 245, 'ch')
        assert_equal("CH", code.country)
        assert_equal("%05i", code.format)
        assert_equal("00245", code.to_s)
      end
      def test_equal
        code1 = Code.new(:registration, 245, 'ch')
        code2 = Code.new(:registration, 245, 'ch')
        code3 = Code.new(:registration, 245, 'de')
        code4 = Code.new(:registration, 246, 'ch')
        code5 = Code.new(:substance, 245, 'ch')
        assert_equal(true, code1 == code2)
        assert_equal(true, code2 == code1)
        assert_equal(false, code1 == code3)
        assert_equal(false, code3 == code1)
        assert_equal(false, code1 == code4)
        assert_equal(false, code4 == code1)
        assert_equal(false, code1 == code5)
        assert_equal(false, code5 == code1)
        assert_equal(true, [code1].include?(code2))
        assert_equal(false, [code1].include?(code3))
        assert_equal(false, [code1].include?(code4))
        assert_equal(false, [code1].include?(code5))
      end
      def test_hash_key
        code1 = Code.new(:registration, 245, 'ch')
        code2 = Code.new(:registration, 245, 'ch')
        code3 = Code.new(:registration, 245, 'de')
        assert_equal("found", {code1 => "found"}[code2])
        assert_nil({code1 => "found"}[code3])
      end
      def test_dated_values
        code = Code.new(:registration, 245, 'ch')
        assert_equal("00245", code.to_s)
        code.value = 244, Date.today - 10
        assert_equal(245, code.value)
        assert_equal(244, code.value(Date.today - 1))
        code.value = 246, Date.today + 10
        assert_equal(245, code.value)
        assert_equal(244, code.value(Date.today - 1))
        assert_equal(245, code.value(Date.today + 1))
        assert_equal(246, code.value(Date.today + 10))
      end
      def test_include
        code1 = Code.new(:registration, 245, 'ch')
        code2 = Code.new(:registration, 245, 'de')
        code = Code.new(:registration, 245, 'ch')
        assert_equal(true, [code1].include?(code))
        assert_equal(false, [code2].include?(code))
      end
    end
  end
end
