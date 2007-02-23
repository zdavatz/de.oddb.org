#!/usr/bin/env ruby
# Import::Csv::TestProductInfos -- de.oddb.org -- 13.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/import/csv'
require 'stub/model'

module ODDB
  module Import
    module Csv
class TestProductInfos < Test::Unit::TestCase
  def setup
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @path = File.expand_path('csv/products.csv', @data_dir) 
    @import = ProductInfos.new
    Drugs::Package.instances.clear
  end
  def test_import
    package1 = Drugs::Package.new
    package1.add_code(Util::Code.new(:cid, "8999084", 'DE'))
    package1.save
    sequence1 = Drugs::Sequence.new
    package1.sequence = sequence1
    product1 = Drugs::Product.new
    sequence1.product = product1

    package2 = Drugs::Package.new
    package2.add_code(Util::Code.new(:cid, "8999552", 'DE'))
    package2.add_code(Util::Code.new(:prescription, true, 'DE'))
    package2.save
    sequence2 = Drugs::Sequence.new
    package2.sequence = sequence2
    product2 = Drugs::Product.new
    sequence2.product = product2
    company = Business::Company.new
    product2.company = company

    package3 = Drugs::Package.new
    package3.add_code(Util::Code.new(:cid, "8999575", 'DE'))
    package3.save
    sequence3 = Drugs::Sequence.new
    package3.sequence = sequence3
    product3 = Drugs::Product.new
    sequence3.product = product3

    package4 = Drugs::Package.new
    package4.add_code(Util::Code.new(:cid, "8999612", 'DE'))
    package4.add_code(Util::Code.new(:prescription, false, 'DE'))
    package4.save
    sequence4 = Drugs::Sequence.new
    package4.sequence = sequence4
    product4 = Drugs::Product.new
    sequence4.product = product4

    input = open(@path)
    @import.import(input)

    ## for now, no new packages are created.
    assert_equal([package1, package2, package3, package4],
                 Drugs::Package.instances)
    assert_equal(false, package1.code(:prescription).value)
    assert_equal('Aframed GmbH', product1.company.name.de)
    assert_equal(false, package2.code(:prescription).value)
    assert_equal(company, product2.company)
    assert_equal(true, package3.code(:prescription).value)
    assert_equal('Heumann Ph GmbH & Co. KG', product3.company.name.de)
    assert_equal(true, package4.code(:prescription).value)
    assert_equal('Heumann Ph GmbH & Co. KG', product4.company.name.de)
    assert_equal(product3.company, product4.company)
  end
end
    end
  end
end
