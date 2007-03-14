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
    part1 = Drugs::Part.new
    package1.add_part(part1)
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
    part4 = Drugs::Part.new
    part4.size = 1
    package4.add_part(part4)
    package4.save
    substance4 = Drugs::Substance.new
    substance4.name.de = 'Furosemid'
    substance4.save
    agent4 = Drugs::ActiveAgent.new(substance4, 10000)
    composition4 = Drugs::Composition.new
    composition4.add_active_agent(agent4)
    sequence4 = Drugs::Sequence.new
    sequence4.add_composition(composition4)
    package4.sequence = sequence4
    product4 = Drugs::Product.new
    sequence4.product = product4

    package5 = Drugs::Package.new
    package5.add_code(Util::Code.new(:cid, "8999629", 'DE'))
    package5.add_code(Util::Code.new(:prescription, false, 'DE'))
    package5.sequence = sequence4
    part5 = Drugs::Part.new
    part5.size = 1
    package5.add_part(part5)
    package5.save
    agent5 = Drugs::ActiveAgent.new(substance4, 25000)
    composition5 = Drugs::Composition.new
    composition5.add_active_agent(agent5)
    sequence5 = Drugs::Sequence.new
    sequence5.add_composition(composition5)
    package5.sequence = sequence5
    sequence5.product = product4

    package6 = Drugs::Package.new
    package6.add_code(Util::Code.new(:cid, "8999635", 'DE'))
    package6.add_code(Util::Code.new(:prescription, false, 'DE'))
    package6.sequence = sequence4
    part6 = Drugs::Part.new
    part6.size = 1
    package6.add_part(part6)
    package6.save
    package6.sequence = sequence5

    package7 = Drugs::Package.new
    package7.add_code(Util::Code.new(:cid, "2092271", 'DE'))
    package7.add_code(Util::Code.new(:prescription, false, 'DE'))
    agent7 = Drugs::ActiveAgent.new(substance4, 25000)
    composition7 = Drugs::Composition.new
    composition7.add_active_agent(agent7)
    sequence7 = Drugs::Sequence.new
    sequence7.add_composition(composition7)
    sequence7.product = product4
    package7.sequence = sequence7
    part7 = Drugs::Part.new
    part7.size = 1
    package7.add_part(part7)
    package7.save

    package8 = Drugs::Package.new
    package8.add_code(Util::Code.new(:cid, "2093187", 'DE'))
    package8.add_code(Util::Code.new(:prescription, false, 'DE'))
    package8.sequence = sequence7
    part8 = Drugs::Part.new
    part8.size = 1
    package8.add_part(part8)
    package8.save

    input = open(@path)
    @import.import(input)

    ## for now, no new packages are created.
    assert_equal([ package1, package2, package3, package4, package5, 
                   package6, package7, package8], 
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

    assert_equal(Drugs::Dose.new(50, 'ml'), part1.quantity)

    assert_equal("Biotin Hermes 2,5 mg Tabletten", package2.name.de)


    assert_equal(20, part4.size)
    assert_equal([Drugs::Dose.new(500, 'mg')], sequence4.doses)
    assert_equal(2, sequence4.packages.size)
    assert_equal([package4, package5], sequence4.packages)
    assert_equal([Drugs::Dose.new(250, 'mg')], package6.sequence.doses)

    assert_equal(5, part7.multi)
    assert_equal(10, part7.size)

    assert_equal(40, part8.multi)
    assert_equal(5, part8.size)
    assert_equal(Drugs::Dose.new(20, 'ml'), part8.quantity)
  end
  def test_import_row__tropfen
    package = Drugs::Package.new
    package.add_code(Util::Code.new(:cid, "7448548", 'DE'))
    part = Drugs::Part.new
    package.add_part(part)
    package.save
    sequence = Drugs::Sequence.new
    package.sequence = sequence
    product = Drugs::Product.new
    sequence.product = product

    src = <<-EOS
"7448548";"TRAMADOL Tropfen";"Rezeptpflichtig";"10";"ml";"Tropfen";9.3193;9.3193;"1";"WINTHROP ARZNEIM.GMBH";"nein";"nein"
    EOS
    row = CSV.parse(src, ';').first
    @import.import_row(row)

    assert_equal(nil, part.multi)
    assert_equal(1, part.size)
    assert_equal(Drugs::Dose.new(10, 'ml'), part.quantity)
  end
  def test_import_row__tropfen__size
    package = Drugs::Package.new
    package.add_code(Util::Code.new(:cid, "7448554", 'DE'))
    part = Drugs::Part.new
    package.add_part(part)
    package.save
    sequence = Drugs::Sequence.new
    package.sequence = sequence
    product = Drugs::Product.new
    sequence.product = product

    src = <<-EOS
"7448554";"TRAMADOL Tropfen";"Rezeptpflichtig";"3X10";"ml";"Tropfen";12.0168;12.0168;"1";"WINTHROP ARZNEIM.GMBH";"nein";"nein"
    EOS
    row = CSV.parse(src, ';').first
    @import.import_row(row)

    assert_equal(nil, part.multi)
    assert_equal(3, part.size)
    assert_equal(Drugs::Dose.new(10, 'ml'), part.quantity)
  end
end
    end
  end
end
