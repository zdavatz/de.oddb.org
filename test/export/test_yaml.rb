#!/usr/bin/env ruby
# Export::Yaml::Test -- de.oddb.org -- 11.10.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))
$: << File.expand_path('..', File.dirname(__FILE__))

require 'drb'
require 'flexmock'
require 'test/unit'
require 'oddb/persistence/odba/export'
require 'oddb/util/money'
require 'stub/model'

module ODDB
  module Export
    module Yaml
class TestOdbaYamlInternals < Test::Unit::TestCase
  include FlexMock::TestCase
  def test_code
    code = ODDB::Util::Code.new("codetype", "codevalue", "country")
    code.extend(ODBA::Persistable)
    assert_equal(['@country', '@type'], code.to_yaml_properties)
    expected = <<-EOS
--- !de.oddb.org,2007/ODDB::Util::Code 
country: COUNTRY
type: codetype
value: codevalue
    EOS
    assert_equal(expected, code.to_yaml)
  end
  def test_company
    company = ODDB::Business::Company.new
    company.name.de = "Test GmbH"
    company.extend(ODBA::Persistable)
    assert_not_nil(company.products)
    assert_equal(['@name'], company.to_yaml_properties)
    expected = <<-EOS
--- !de.oddb.org,2007/ODDB::Business::Company 
name: !de.oddb.org,2007/ODDB::Util::Multilingual 
  canonical: 
    :de: Test GmbH
  synonyms: []

    EOS
    assert_equal(expected, company.to_yaml)
  end
  def test_dose
    dose = ODDB::Drugs::Dose.new(912.5, 'mg')
    dose.extend(ODBA::Persistable)
    assert_equal(['@val', '@unit'], dose.to_yaml_properties)
    expected = <<-EOS
--- !de.oddb.org,2007/ODDB::Drugs::Dose 
val: 912.5
unit: mg
    EOS
    assert_equal(expected, dose.to_yaml)
  end
  def test_export
    p1 = ODDB::Drugs::Product.new
    p1.instance_variable_set('@odba_id', 1)
    p1.extend(ODBA::Persistable)
    p2 = ODDB::Drugs::Product.new
    p2.instance_variable_set('@odba_id', 2)
    p2.extend(ODBA::Persistable)
    flexmock(ODDB::Drugs::Product).should_receive(:all).and_return { |block|
      block.call p1
      block.call p2
    }
    io = StringIO.new
    Drugs.new.export(io)
    expected = <<-EOS
--- !de.oddb.org,2007/ODDB::Drugs::Product 
oid: 1
sequences: []

--- !de.oddb.org,2007/ODDB::Drugs::Product 
oid: 2
sequences: []

    EOS
    io.rewind
    assert_equal expected, io.read
  end
  def test_package
    package = ODDB::Drugs::Package.new
    package.add_price(Util::Money.new(12.50, :public))
    package.sequence = ODDB::Drugs::Sequence.new
    package.add_part(ODDB::Drugs::Part.new)
    package.extend(ODBA::Persistable)
    assert_equal(['@parts'], package.to_yaml_properties)
    expected = <<-EOS
--- !de.oddb.org,2007/ODDB::Drugs::Package 
parts: 
- !de.oddb.org,2007/ODDB::Drugs::Part 
  size: 1
prices: 
  public: 12.5
    EOS
    assert_equal(expected, package.to_yaml)
  end
  def test_product
    assert_respond_to(ODDB::Drugs::Product, :export)
    product = ODDB::Drugs::Product.new
    product.extend(ODBA::Persistable)
    company = ODDB::Business::Company.new
    product.company = company
    assert_equal(['@company', '@sequences'], product.to_yaml_properties)
    expected = <<-EOS
--- !de.oddb.org,2007/ODDB::Drugs::Product 
company: !de.oddb.org,2007/ODDB::Business::Company {}

sequences: []

    EOS
    assert_equal(expected, product.to_yaml)
  end
end
    end
  end
end
