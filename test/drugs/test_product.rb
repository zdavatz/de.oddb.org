#!/usr/bin/env ruby
# Drugs::TestProduct -- de.oddb.org -- 09.08.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/product'

module ODDB
  module Drugs
    class TestProduct < Test::Unit::TestCase
      def setup
        @product = Product.new
      end
      def test_name
        assert_instance_of(Util::Multilingual, @product.name)
      end
    end
  end
end
