#!/usr/bin/env ruby
# Drugs::TestProduct -- de.oddb.org -- 09.08.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/product'

module ODDB
  module Drugs
    class TestProduct < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @product = Product.new
      end
      def test_comparables
        prod1 = flexmock('product')
        prod2 = flexmock('product')
        atc = flexmock('atc')
        atc.should_receive(:products)\
          .and_return([prod1, @product, prod2])
        atc.should_ignore_missing
        @product.atc = atc
        assert_equal([prod1, @product, prod2], @product.comparables)
      end
      def test_name
        assert_instance_of(Util::Multilingual, @product.name)
      end
      def test_packages
        seq1 = flexmock('sequence')
        seq2 = flexmock('sequence')
        seq1.should_receive(:packages).and_return(%w{foo bar})
        seq2.should_receive(:packages).and_return(%w{baz})
        @product.add_sequence(seq1)
        @product.add_sequence(seq2)
        assert_equal(%w{foo bar baz}, @product.packages)
      end
    end
  end
end
