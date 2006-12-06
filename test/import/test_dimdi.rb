#!/usr/bin/env ruby
# Import::TestDimdi -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/import/dimdi'
require 'stub/model'

module ODDB
  module Business
    class Company < Model
      simulate_database(:name)
    end
  end
  module Drugs
    class ActiveAgent < Model
      simulate_database
    end
    class Atc < Model
      simulate_database(:name)
    end
    class Composition < Model
      simulate_database
    end
    class GalenicForm < Model
      simulate_database(:description)
    end
    class Package < Model
      simulate_database
    end
    class Part < Model
      simulate_database
    end
    class Product < Model
      simulate_database(:name)
    end
    class Sequence < Model
      simulate_database
    end
    class Substance < Model
      simulate_database(:name)
    end
    class SubstanceGroup < Model
      simulate_database(:name)
    end
    class Unit < Model
      simulate_database(:name)
    end
  end
  module Import
    class TestDimdiGalenicForm < Test::Unit::TestCase
      def setup
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xls/darform_010706.xls', @data_dir) 
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
        @import.import(input)
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
        @import = DimdiProduct.new
      end
      def test_import_base_data
        assert_equal([], Drugs::Product.instances)
        sub1 = Drugs::Substance.new
        sub1.add_code(Util::Code.new("substance", u("POXM"), 'DE'))
        sub1.save
        tab = Drugs::GalenicForm.new
        code = Util::Code.new("galenic_form", "TABS", "DE")
        tab.add_code(code)
        tab.description.de = "Tabletten"
        tab.save
        input = open(@path)
        @import.import(input)
        assert_equal(10, Drugs::Product.instances.size)
        expected = [ u("Piroxicam Ratio"), u("Amoxicillin Ratio"),
          u("Buscopan Aca"), u("Aquaphor/Il Aca"), u("Aspirin Aca"),
          u("Sibelium Aca"), u("Capto Merckdura"), 
          u("Aknefug/Mino Wolff"), u("Ribofluor"), u("Dexa Ct"), ]
        names = Drugs::Product.instances.collect { |inst|
          inst.name.de
        }
        assert_equal(expected, names)
        pr = Drugs::Product.instances.first
        assert_equal(1, pr.codes.size)
        code = pr.code(:festbetragsgruppe, 'DE')
        assert_instance_of(Util::Code, code)
        assert_equal(u('9'), code.value)
        assert_equal(1, pr.sequences.size)
        seq = pr.sequences.first
        assert_equal(1, seq.compositions.size)
        comp = seq.compositions.first
        assert_equal(1.1, comp.equivalence_factor)
        assert_equal(1, comp.active_agents.size)
        agent = comp.active_agents.first
        assert_equal(sub1, agent.substance)
        assert_equal(1, seq.packages.size)
        pack = seq.packages.first
        assert_equal(34.25, pack.price(:public, 'DE'))
        assert_equal(34.28, pack.price(:festbetrag, 'DE'))
        code = pack.code(:festbetragsstufe, 'DE')
        assert_instance_of(Util::Code, code)
        assert_equal(2, code.value)
        assert_equal(1, pack.parts.size)
        assert_equal(100, pack.size)
        part = pack.parts.first
        assert_instance_of(Drugs::Unit, part.unit)
        assert_equal(u('Tabletten'), part.unit.name.de)
        code = pack.code(:cid, 'DE')
        assert_instance_of(Util::Code, code)
        assert_equal("649", code.value)

        # do it again, nothing should change
        input = open(@path)
        @import.import(input)
        assert_equal(10, Drugs::Product.instances.size)
        names = Drugs::Product.instances.collect { |inst|
          inst.name.de
        }
        assert_equal(expected, names)
        assert_equal(1, pr.codes.size)
        code = pr.code(:festbetragsgruppe)
        assert_instance_of(Util::Code, code)
        assert_equal(u('9'), code.value)
        assert_equal(1, pr.sequences.size)
        seq = pr.sequences.first
        assert_equal(1, seq.compositions.size)
        comp = seq.compositions.first
        assert_equal(1.1, comp.equivalence_factor)
        assert_equal(1, comp.active_agents.size)
        agent = comp.active_agents.first
        assert_equal(sub1, agent.substance)
        assert_equal(1, seq.packages.size)
        pack = seq.packages.first
        assert_equal(34.25, pack.price(:public, 'DE'))
        assert_equal(34.28, pack.price(:festbetrag, 'DE'))
        code = pack.code(:festbetragsstufe, 'DE')
        assert_instance_of(Util::Code, code)
        assert_equal(2, code.value)
        assert_equal(1, pack.parts.size)
        assert_equal(100, pack.size)
        part = pack.parts.first
        assert_instance_of(Drugs::Unit, part.unit)
        assert_equal(u('Tabletten'), part.unit.name.de)
        code = pack.code(:cid, 'DE')
        assert_instance_of(Util::Code, code)
        assert_equal("649", code.value)
      end
    end
    class TestDimdiSubstance < Test::Unit::TestCase
      def setup
        Drugs::Substance.instances.clear
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xls/wirkkurz_010406.xls', @data_dir) 
        @import = DimdiSubstance.new
      end
      def test_import
        assert_equal([], Drugs::Substance.instances)
        input = open(@path)
        @import.import(input)
        assert_equal(5, Drugs::Substance.instances.size)
        expected = [u("Acebutolol"), u("Aceclofenac"),
          u("Atenolol+Chlort+Hydralazin"), u("Acemetacin"),
          u("Almotriptan")]
        names = Drugs::Substance.instances.collect { |inst|
          inst.name.de
        }
        assert_equal(expected, names)
        # do it again, nothing should change
        input = open(@path)
        @import.import(input)
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
    class TestDimdiZuzahlungsBefreiung < Test::Unit::TestCase
      def setup
        Drugs::Product.instances.clear
        Drugs::Substance.instances.clear
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xls/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls', @data_dir) 
        @import = DimdiZuzahlungsBefreiung.new
      end
      def test_import
        atc = Drugs::Atc.new('M04AA51')
        atc.name.de = 'Allopurinol, Kombinationen'
        atc.save
        existing = Drugs::Package.new
        existing.add_code(Util::Code.new(:cid, '2542946', 'DE'))
        existing.add_part(Drugs::Part.new)
        existing.save
        sequence = Drugs::Sequence.new
        product = Drugs::Product.new
        existing.sequence = sequence
        sequence.product = product
        input = open(@path)
        assert_nil(existing.code(:zuzahlungsbefreit))
        @import.import(input)
        assert_equal(1, Drugs::Product.instances.size)
        assert_equal([product], Drugs::Product.instances)
        assert_equal(atc, product.atc)
        assert_equal([product], atc.products)
        assert_equal(1, product.sequences.size)
        sequence = product.sequences.first
        assert_equal(1, sequence.compositions.size)
        composition = sequence.compositions.first
        assert_equal(2, composition.active_agents.size)
        agent1 = composition.active_agents.at(0)
        agent2 = composition.active_agents.at(1)
        assert_equal('Allopurinol', agent1.substance.name.de)
        assert_equal(Drugs::Dose.new(100, 'mg'), agent1.dose)
        assert_equal('Benzbromaron', agent2.substance.name.de)
        assert_equal(Drugs::Dose.new(20, 'mg'), agent2.dose)
        code = existing.code(:zuzahlungsbefreit)
        assert_instance_of(Util::Code, code)
        assert_equal(true, code.value)

        # do it again, nothing should change
        input = open(@path)
        @import.import(input)
        assert_equal(1, Drugs::Product.instances.size)
        assert_equal([product], Drugs::Product.instances)
        assert_equal(atc, product.atc)
        assert_equal([product], atc.products)
        assert_equal(1, product.sequences.size)
        sequence = product.sequences.first
        assert_equal(1, sequence.compositions.size)
        composition = sequence.compositions.first
        assert_equal(2, composition.active_agents.size)
        agent1 = composition.active_agents.at(0)
        agent2 = composition.active_agents.at(1)
        assert_equal('Allopurinol', agent1.substance.name.de)
        assert_equal(Drugs::Dose.new(100, 'mg'), agent1.dose)
        assert_equal('Benzbromaron', agent2.substance.name.de)
        assert_equal(Drugs::Dose.new(20, 'mg'), agent2.dose)
        assert_instance_of(Util::Code, code)
        assert_equal(true, code.value)
      end
    end
  end
end
