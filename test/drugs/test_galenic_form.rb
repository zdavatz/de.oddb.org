#!/usr/bin/env ruby
# Drugs::TestGalenicForm -- de.oddb.org -- 21.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/galenic_form'

module ODDB
  module Drugs
    class TestGalenicForm < Test::Unit::TestCase
      def setup
        @galenic_form = GalenicForm.new
      end
      def test_equal
        other = GalenicForm.new
        assert_equal(true, @galenic_form == @galenic_form)
        assert_equal(false, @galenic_form == other)
        assert_equal(false, other == @galenic_form)
        assert_equal(false, @galenic_form == nil)

        group = GalenicGroup.new('Tabletten')
        @galenic_form.group = group
        assert_equal(true, @galenic_form == @galenic_form)
        assert_equal(false, @galenic_form == other)
        assert_equal(false, other == @galenic_form)
        assert_equal(false, @galenic_form == nil)

        other.group = GalenicGroup.new('Salben')
        assert_equal(true, @galenic_form == @galenic_form)
        assert_equal(false, @galenic_form == other)
        assert_equal(false, other == @galenic_form)

        other.group = group
        assert_equal(true, @galenic_form == @galenic_form)
        assert_equal(true, @galenic_form == other)
        assert_equal(true, other == @galenic_form)
      end
    end
  end
end
