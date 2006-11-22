#!/usr/bin/env ruby
# Business::TestCompany -- de.oddb.org -- 22.11.2006 -- hwyss@ywesee.com


$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/business/company'

module ODDB
  module Business
    class TestCompany < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @company = Company.new
      end
      def test_packages
        prod1 = flexmock('product')
        prod2 = flexmock('product')
        @company.add_product(prod1)
        @company.add_product(prod2)
        prod1.should_receive(:packages).and_return(['foo', 'bar'])
        prod2.should_receive(:packages).and_return(['baz'])
        assert_equal(['foo', 'bar', 'baz'], @company.packages)
      end
    end
  end
end
