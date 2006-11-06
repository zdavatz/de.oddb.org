#!/usr/bin/env ruby
# TestMultilingual -- de.oddb.org -- 05.09.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/util/multilingual'
require 'encoding/character/utf-8'

module ODDB
  module Util
    class TestMultiLingual < Test::Unit::TestCase
      def setup
        @ml = Multilingual.new
      end
      def test_canonical_reader
        assert_equal(nil, @ml.de)
        assert_equal(nil, @ml.fr)
        @ml.canonical.store(:de, 'Ein Test')
        assert_equal('Ein Test', @ml.de)
        assert_equal(nil, @ml.fr)
        @ml.canonical.store(:fr, 'Un Test')
        assert_equal('Ein Test', @ml.de)
        assert_equal('Un Test', @ml.fr)
      end
      def test_canonical_writer
        assert_equal({}, @ml.canonical)
        @ml.de = 'Ein Test'
        assert_equal({:de => 'Ein Test'}, @ml.canonical)
        @ml.fr = 'Un Test'
        assert_equal({:de => 'Ein Test', :fr => 'Un Test'}, @ml.canonical)
      end
      def test_method_missing
        assert_raises(NoMethodError) { @ml.foo }
      end
      def test_equals__canonical
        assert_equal(false, @ml == nil)
        assert_equal(false, @ml == 'test')
        assert_equal(false, @ml == 'tset')
        @ml.de = "test"
        assert_equal(false, @ml == nil)
        assert_equal(true, @ml == 'test')
        assert_equal(false, @ml == 'tset')
      end
      def test_equals__canonical__ustr
        assert_equal(false, @ml == nil)
        assert_equal(false, @ml == u('test'))
        assert_equal(false, @ml == u('tset'))
        @ml.de = "test"
        assert_equal(false, @ml == nil)
        assert_equal(true, @ml == u('test'))
        assert_equal(false, @ml == u('tset'))
        @ml.de = u("test")
        assert_equal(false, @ml == nil)
        assert_equal(true, @ml == u('test'))
        assert_equal(false, @ml == u('tset'))
      end
      def test_equals__canonical__other_ml
        ml = Multilingual.new
        assert_equal(true, @ml == ml)
        ml.de = 'test'
        assert_equal(false, @ml == ml)
        ml.de = 'tset'
        assert_equal(false, @ml == ml)
        ml = Multilingual.new
        @ml.de = "test"
        assert_equal(false, @ml == ml)
        ml.de = 'test'
        assert_equal(true, @ml == ml)
        ml.de = 'tset'
        assert_equal(false, @ml == ml)
        @ml.de = "test"
      end
      def test_equals__synonym
        assert_equal(false, @ml == nil)
        assert_equal(false, @ml == 'test')
        assert_equal(false, @ml == 'tset')
        @ml.synonyms.push("test")
        assert_equal(false, @ml == nil)
        assert_equal(true, @ml == 'test')
        assert_equal(false, @ml == 'tset')
      end
      def test_all
        @ml.de = "de-value"
        assert_equal(['de-value'], @ml.all)
        @ml.fr = "fr-value"
        assert_equal(['de-value', 'fr-value'], @ml.all.sort)
        @ml.synonyms.push('synonym')
        assert_equal(['de-value', 'fr-value', 'synonym'], @ml.all.sort)
      end
      def test_find
        @ml.de = 'test'
        assert_equal(@ml, [@ml].find { |elm| elm == 'test'})
      end
    end
  end
end
