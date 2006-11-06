#!/usr/bin/env ruby
# Import::TestDimdi -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/import/dimdi'

class Object
  def metaclass; class << self; self; end; end
  def meta_eval &blk; metaclass.instance_eval &blk; end
end
module ODDB
  class Model
    class << self
      def simulate_database(name)
        meta_eval {
          define_method(:instances) {
            @instances ||= []
          }
          define_method("find_by_#{name}") { |nme|
            instances.find { |instance| instance.send(name) == nme }
          }
          define_method(:find_by_code) { |criteria|
            instances.find { |instance| instance.codes.any? { |code| 
              code == criteria[:value] } }
          }
        }
        define_method(:save) {
          self.class.instances.push(self).uniq!
        }
      end
    end
  end
  module Drugs
    class GalenicForm < Model
      simulate_database(:description)
    end
    class Product < Model
      simulate_database(:name)
    end
    class Substance < Model
      simulate_database(:name)
    end
  end
  module Import
    class TestDimdiGalenicForm < Test::Unit::TestCase
      def setup
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xls/darform_010706.xls', @data_dir) 
        @input = open(@path)
        @import = DimdiGalenicForm.new
      end
      def test_import
        input = open(@path)
        assert_equal([], Drugs::GalenicForm.instances)
        @import.import(input)
        assert_equal(3, Drugs::GalenicForm.instances.size)
        expected = [u("Aerolizer"), u("Ampullen"), u("Depotampullen")]
        names = Drugs::GalenicForm.instances.collect { |inst|
          inst.description.de
        }
        assert_equal(expected, names)
        # do it again, nothing should change
        input = open(@path)
        @import.import(@input)
        assert_equal(3, Drugs::GalenicForm.instances.size)
        names = Drugs::GalenicForm.instances.collect { |inst|
          inst.description.de
        }
        assert_equal(expected, names)
        galenic_form = Drugs::GalenicForm.instances.last
        assert_instance_of(Drugs::GalenicForm, galenic_form)
        assert_equal(2, galenic_form.codes.size)
        code = galenic_form.codes.first
        assert_instance_of(Util::Code, code)
        assert_equal('DE', code.country)
        assert_equal("galenic_form", code.type)
        assert_equal('AMPD', code.value)
        code = galenic_form.codes.last
        assert_instance_of(Util::Code, code)
        assert_equal('DE', code.country)
        assert_equal("galenic_form", code.type)
        assert_equal('AMPD1', code.value)
      end
    end
    class TestDimdiProduct < Test::Unit::TestCase
      def setup
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xls/fb010706.xls', @data_dir) 
        @input = open(@path)
        @import = DimdiProduct.new
      end
      def test_import_base_data
        @import.import(@input)
      end
    end
    class TestDimdiSubstance < Test::Unit::TestCase
      def setup
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xls/wirkkurz_010406.xls', @data_dir) 
        @input = open(@path)
        @import = DimdiSubstance.new
      end
      def test_import
        input = open(@path)
        assert_equal([], Drugs::Substance.instances)
        @import.import(input)
        assert_equal(5, Drugs::Substance.instances.size)
        expected = [u("Acebutolol"), u("Aceclofenac"),
          u("Atenolol+Chlort+Hydralazin"), u("Acemetacin"), u("Almotriptan")]
        names = Drugs::Substance.instances.collect { |inst|
          inst.name.de
        }
        assert_equal(expected, names)
        # do it again, nothing should change
        input = open(@path)
        @import.import(@input)
        assert_equal(5, Drugs::Substance.instances.size)
        names = Drugs::Substance.instances.collect { |inst|
          inst.name.de
        }
        assert_equal(expected, names)
        substance = Drugs::Substance.instances.first
        assert_instance_of(Drugs::Substance, substance)
        assert_equal(1, substance.codes.size)
        code = substance.codes.first
        assert_instance_of(Util::Code, code)
        assert_equal('DE', code.country)
        assert_equal("substance", code.type)
        assert_equal('ABTL', code.value)
      end
    end
  end
end
