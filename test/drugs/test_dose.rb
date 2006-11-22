#!/usr/bin/env ruby
# Drugs::TestDose -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com 

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/drugs/dose'

module ODDB
  module Drugs
class TestDose < Test::Unit::TestCase
  def setup
    @dose = Dose.new('1,7', 'mL')
  end
  def test_initialize1
    vals = ['Aspirin, Tabletten', '12', '500', 'mg', 'D']
    dose = Dose.new(*vals[2,2])
    assert_equal(500, dose.qty)
    assert_equal('mg', dose.unit.to_s)
    assert_equal('500 mg', dose.to_s)
  end
  def test_initialize2
    vals = ['Hametum, Salbe', '62.5', 'mg/g', 'D']
    dose = Dose.new(*vals[1,2])
    assert_equal(62.5, dose.qty)
    assert_equal('mg/g', dose.unit.to_s)
    assert_equal('62.5 mg/g', dose.to_s)
  end
  def test_initialize3
    dose = Dose.new('1,7', 'mL')
    assert_equal(1.7, dose.qty)
    assert_equal('ml', dose.unit.to_s)
    assert_equal('1.7 ml', dose.to_s)
  end
  def test_initialize4
    compare = Dose.new(6.25, 'mg/g')
    vals = ['62.5', 'mg/10g']
    dose = Dose.new(*vals)
    assert_equal(6.25, dose.qty)
    assert_equal('mg/g', dose.unit.to_s)
    assert_equal('62.5mg / 10g', dose.to_s)
    assert_equal(0, compare<=>dose)
    assert_equal(compare, dose)
  end
  def test_initialize5
    compare = Dose.new(0.5, 'mg/ml')
    vals = [1, 'mg/2ml']
    dose = Dose.new(*vals)
    assert_equal(0.5, dose.qty)
    assert_equal('mg/ml', dose.unit.to_s)
    assert_equal('1mg / 2ml', dose.to_s)
    assert_equal(0, compare<=>dose)
    assert_equal(compare, dose)
  end
  def test_initialize6
    vals = ['62.5', ' mg / 10g']
    dose = Dose.new(*vals)
    assert_equal(6.25, dose.qty)
    assert_equal('mg/g', dose.unit.to_s)
    assert_equal('62.5mg / 10g', dose.to_s)
  end
  def test_initialize7
    dose = Dose.new('0.025', '%')
    assert_equal(0.025, dose.qty)
    assert_equal('%', dose.unit.to_s)
    assert_equal('0.025 %', dose.to_s)
  end
  def test_initialize8
    dose = Dose.new('40-60', 'mg')
    assert_equal(50, dose.qty)
    assert_equal('mg', dose.unit.to_s)
    assert_equal('40-60 mg', dose.to_s)
  end
  def test_comparable1
    dose1 = Dose.new(10, 'mg')
    dose2 = Dose.new(10, 'mg')
    assert_equal(dose1, dose2)
  end
  def test_comparable2
    dose1 = Dose.new(10, 'mg')
    dose2 = Dose.new(10, 'g')
    assert(dose2 > dose1, "dose2 was not > dose1")
  end
  def test_comparable3
    dose1 = Dose.new(1000, 'I.E.')
    dose2 = Dose.new(500, 'I.E.')
    assert(dose2 < dose1, "dose2 was not < dose1")
  end
  def test_comparable4
    dose1 = Dose.new(1000, 'mg')
    dose2 = Dose.new(500, 'I.E.')
    assert_equal(-1, dose2 <=> dose1, "dose2 was not < dose1")
  end
  def test_comparable5
    dose1 = Dose.new(1000, 'mg')
    dose2 = Dose.new(500, 'l')
    assert_equal(-1, dose2 <=> dose1, "dose2 was not < dose1")
  end
  def test_comparable6
    dose1 = Dose.new(1000, 'mg')
    dose2 = Dose.new(1, 'g')
    assert(dose2 == dose1, "dose2 was not == dose1")
  end
  def test_comparable7
    dose1 = Dose.new('400-600', 'mg')
    dose2 = Dose.new('0.4-0.6', 'g')
    assert(dose2 == dose1, "dose2 was not == dose1")
  end
  def test_comparable8
    dose1 = Dose.new('1000', 'µg')
    dose2 = Dose.new('1', 'mg')
    assert(dose2 == dose1, "dose2 was not == dose1")
  end
  def test_comparable9
    dose1 = Dose.new(1000)
    assert(dose1 == 1000, "Dose was not equal to equivalent Fixnum")
    assert(1000 == dose1, "Fixnum was not equal to equivalent Dose")
  end
  def test_comparable10
    dose1 = Dose.new(1000)
    dose2 = Dose.new(1000, 'mg')
    dose3 = Dose.new(500)
    dose4 = Dose.new(1000)
    assert_equal(-1, dose1 <=> dose2)
    assert_equal(1, dose2 <=> dose1)
    assert_equal(-1, dose3 <=> dose1)
    assert_equal(1, dose1 <=> dose3)
    assert_equal(0, dose1 <=> dose4)
  end
  def test_complex_unit
    dose = nil
    assert_nothing_raised {
      dose = Dose.new(20.0, 'mg/5ml')
    }
  end
  def test_from_quanty  
    quanty = Quanty.new(1,'mg')
    result = Dose.from_quanty(quanty)
    assert_instance_of(Dose, result)
    assert_equal(Dose.new(1, 'mg'), result)
  end  
  def test_addition
    dose1 = Dose.new(7,'ml')
    dose2 = Dose.new(1,'cl')
    assert_equal(Dose.new(1.7, 'cl'), dose1 + dose2)
  end
  def test_subtraction
    dose1 = Dose.new(1,'cl')
    dose2 = Dose.new(7,'ml')
    assert_equal(Dose.new(0.3, 'cl'), dose1 - dose2)
  end
  def test_multiplication
    dose1 = Dose.new(1,'ml')
    dose2 = Dose.new(1.7,'kg')
    assert_equal(Dose.new(1.7, 'ml kg'), dose1 * dose2)
  end
  def test_division
    dose1 = Dose.new(0.2,'g')
    dose2 = Dose.new(100,'ml')
    assert_equal(Dose.new(2, 'mg/ml'), dose1 / dose2)
  end
  def test_robust_initalizer
    assert_nothing_raised {
      Dose.new(12)
    }
  end
  def test_range
    dose = nil
    assert_nothing_raised {
      dose = Dose.new(1..5, 'mg')
    }
    assert_equal('1-5 mg', dose.to_s)
  end
  def test_robust_to_f
    dose = Dose.new(12, 'mg')
    assert_nothing_raised {
      dose.to_f
    }
  end
  def test_robust_to_i
    dose = Dose.new(12, 'mg')
    assert_nothing_raised {
      dose.to_i
    }
    assert_equal(12, dose.to_i)
  end
end
  end
end
