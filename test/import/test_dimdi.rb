#!/usr/bin/env ruby
# Import::TestDimdi -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/import/dimdi'
require 'stub/model'
require 'flexmock'

module ODDB
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
        atc = Drugs::Atc.new('M04AA51')
        atc.name.de = 'Amoxicillin, Fuzzy match'
        atc.save
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
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(11, Drugs::Product.instances.size)
        expected = [ u("Piroxicam Ratio"), u("Amoxicillin Ratio"),
          u("Buscopan Aca"), u("Aquaphor/Il Aca"), u("Aspirin Aca"),
          u("Sibelium Aca"), u("Capto Merckdura"), 
          u("Aknefug/Mino Wolff"), u("Ribofluor"), u("Dexa Ct"), 
          u("Madopar Emra"), ]
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

        pr = Drugs::Product.instances.at(1)
        assert_equal(atc, pr.atc)

        pr = Drugs::Product.instances.last
        seq = pr.sequences.first
        comp = seq.compositions.first
        assert_equal(2, comp.active_agents.size)
        assert_equal(["Levodopa", "Benserazid"], 
                     comp.substances.collect { |sub| sub.name.de })
        assert_equal([Drugs::Dose.new(0,'mg'), Drugs::Dose.new(0,'mg')],
                     comp.doses)

        # do it again, nothing should change
        input = open(@path)
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(11, Drugs::Product.instances.size)
        names = Drugs::Product.instances.collect { |inst|
          inst.name.de
        }
        assert_equal(expected, names)
        pr = Drugs::Product.instances.first
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

        pr = Drugs::Product.instances.at(1)
        assert_equal(atc, pr.atc)

        pr = Drugs::Product.instances.last
        seq = pr.sequences.first
        comp = seq.compositions.first
        assert_equal(2, comp.active_agents.size)
        assert_equal(["Levodopa", "Benserazid"], 
                     comp.substances.collect { |sub| sub.name.de })
        assert_equal([Drugs::Dose.new(0,'mg'), Drugs::Dose.new(0,'mg')],
                     comp.doses)
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
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(7, Drugs::Substance.instances.size)
        expected = [u("Acebutolol"), u("Aceclofenac"), u("Atenolol"),
          u("Chlort"), u("Hydralazin"), u("Acemetacin"),
          u("Almotriptan")]
        names = Drugs::Substance.instances.collect { |inst|
          inst.name.de
        }
        assert_equal(expected, names)
        # do it again, nothing should change
        input = open(@path)
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(7, Drugs::Substance.instances.size)
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
      include FlexMock::TestCase
      def setup
        Drugs::Package.instances.clear
        Drugs::Product.instances.clear
        Drugs::Substance.instances.clear
        Business::Company.instances.clear
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
        report = @import.import(input)
        assert_instance_of(Array, report)
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
        confirmed = @import.instance_variable_get('@confirmed_pzns')
        assert_equal(1, confirmed.size)

        # do it again, nothing should change
        input = open(@path)
        report = @import.import(input)
        assert_instance_of(Array, report)
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
        confirmed = @import.instance_variable_get('@confirmed_pzns')
        assert_equal(1, confirmed.size)
      end
      def test_import__ml
        atc = Drugs::Atc.new('J01CA04')
        atc.name.de = 'Amoxicillin'
        atc.save
        existing = Drugs::Package.new
        existing.add_code(Util::Code.new(:cid, '3525921', 'DE'))
        existing.add_part(Drugs::Part.new)
        existing.save
        sequence = Drugs::Sequence.new
        product = Drugs::Product.new
        existing.sequence = sequence
        sequence.product = product
        input = open(@path)
        assert_nil(existing.code(:zuzahlungsbefreit))
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(1, Drugs::Product.instances.size)
        assert_equal([product], Drugs::Product.instances)
        assert_equal(atc, product.atc)
        assert_equal([product], atc.products)
        assert_equal(1, product.sequences.size)
        sequence = product.sequences.first
        assert_equal(1, sequence.compositions.size)
        composition = sequence.compositions.first
        assert_equal(1, composition.active_agents.size)
        agent1 = composition.active_agents.at(0)
        assert_equal('Amoxicillin-3-Wasser', agent1.substance.name.de)
        assert_equal(Drugs::Dose.new(287, 'mg'), agent1.dose)
        code = existing.code(:zuzahlungsbefreit)
        assert_instance_of(Util::Code, code)
        assert_equal(true, code.value)
        assert_equal(1, existing.parts.size)
        part = existing.parts.first
        assert_equal(2, part.size)
        assert_equal('100 ml', part.quantity.to_s)

        # do it again, nothing should change
        input = open(@path)
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(1, Drugs::Product.instances.size)
        assert_equal([product], Drugs::Product.instances)
        assert_equal(atc, product.atc)
        assert_equal([product], atc.products)
        assert_equal(1, product.sequences.size)
        sequence = product.sequences.first
        assert_equal(1, sequence.compositions.size)
        composition = sequence.compositions.first
        assert_equal(1, composition.active_agents.size)
        agent1 = composition.active_agents.at(0)
        assert_equal('Amoxicillin-3-Wasser', agent1.substance.name.de)
        assert_equal(Drugs::Dose.new(287, 'mg'), agent1.dose)
        code = existing.code(:zuzahlungsbefreit)
        assert_instance_of(Util::Code, code)
        assert_equal(true, code.value)
        assert_equal(1, existing.parts.size)
        part = existing.parts.first
        assert_equal(2, part.size)
        assert_equal('100 ml', part.quantity.to_s)
      end
      def test_import__chemical_form
        atc = Drugs::Atc.new('N04BB01')
        atc.name.de = 'Amantadin'
        atc.save
        existing = Drugs::Package.new
        existing.add_code(Util::Code.new(:cid, '183762', 'DE'))
        existing.add_part(Drugs::Part.new)
        substance1 = Drugs::Substance.new
        substance1.name.de = 'Amantadin'
        active_agent = Drugs::ActiveAgent.new(substance1, 200)
        substance2 = Drugs::Substance.new
        substance2.name.de = 'Amantadini sulfas'
        equivalence = Drugs::ActiveAgent.new(substance2, nil)
        active_agent.chemical_equivalence = equivalence
        composition = Drugs::Composition.new
        composition.add_active_agent(active_agent)
        part = Drugs::Part.new
        part.composition = composition
        existing.add_part(part)
        existing.save
        sequence = Drugs::Sequence.new
        sequence.add_composition(composition)
        product = Drugs::Product.new
        existing.sequence = sequence
        sequence.product = product
        input = open(@path)
        assert_nil(existing.code(:zuzahlungsbefreit))
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(1, Drugs::Product.instances.size)
        assert_equal([product], Drugs::Product.instances)
        assert_equal(atc, product.atc)
        assert_equal([product], atc.products)
        assert_equal(1, product.sequences.size)
        sequence = product.sequences.first
        assert_equal(1, sequence.compositions.size)
        composition = sequence.compositions.first
        assert_equal(1, composition.active_agents.size)
        agent1 = composition.active_agents.at(0)
        assert_equal(active_agent, agent1)
        assert_equal(Drugs::Dose.new(200, 'mg'), agent1.dose)
        equ = agent1.chemical_equivalence
        assert_instance_of(Drugs::ActiveAgent, equ)
        assert_equal('Amantadin sulfat', equ.substance.name.de)
        assert_equal(Drugs::Dose.new(100, 'mg'), equ.dose)
        code = existing.code(:zuzahlungsbefreit)
        assert_instance_of(Util::Code, code)
        assert_equal(true, code.value)

        # do it again, nothing should change
        input = open(@path)
        report = @import.import(input)
        assert_instance_of(Array, report)
        assert_equal(1, Drugs::Product.instances.size)
        assert_equal([product], Drugs::Product.instances)
        assert_equal(atc, product.atc)
        assert_equal([product], atc.products)
        assert_equal(1, product.sequences.size)
        sequence = product.sequences.first
        assert_equal(1, sequence.compositions.size)
        composition = sequence.compositions.first
        assert_equal(1, composition.active_agents.size)
        agent1 = composition.active_agents.at(0)
        assert_equal(active_agent, agent1)
        assert_equal(Drugs::Dose.new(200, 'mg'), agent1.dose)
        equ = agent1.chemical_equivalence
        assert_instance_of(Drugs::ActiveAgent, equ)
        assert_equal('Amantadin sulfat', equ.substance.name.de)
        assert_equal(Drugs::Dose.new(100, 'mg'), equ.dose)
        code = existing.code(:zuzahlungsbefreit)
        assert_instance_of(Util::Code, code)
        assert_equal(true, code.value)
      end
      def test_postprocess
        product = Drugs::Product.new
        product.name.de = 'Product 100% Company'
        product.save
        company = Business::Company.new
        company.name.de = 'Company AG'
        company.save
        @import.postprocess
        assert_equal(company, product.company)
      end
      def test_postprocess__comp
        product = Drugs::Product.new
        product.name.de = 'Product 100% Producer Comp'
        product.save
        company = Business::Company.new
        company.name.de = 'Producer AG'
        company.save
        @import.postprocess
        assert_equal(company, product.company)
      end
      def test_postprocess__search
        product = Drugs::Product.new
        product.name.de = 'Product 100% Manu'
        product.save
        company = Business::Company.new
        company.name.de = 'Manufacturer AG'
        company.save
        @import.postprocess
        assert_equal(company, product.company)
      end
      def test_postprocess__prune_packages
        pzn1 = Util::Code.new(:pzn, '12345', 'DE')
        zzb1 = Util::Code.new(:zuzahlungsbefreit, 'true', 'DE')
        pac1 = Drugs::Package.new
        pac1.add_code(pzn1)
        pac1.add_code(zzb1)
        pac1.save
        pzn2 = Util::Code.new(:pzn, '54321', 'DE')
        zzb2 = Util::Code.new(:zuzahlungsbefreit, 'true', 'DE')
        pac2 = Drugs::Package.new
        pac2.add_code(pzn2)
        pac2.add_code(zzb2)
        pac2.save
        @import.instance_variable_set('@confirmed_pzns', 
                                     pac1.code(:pzn) => true)
        @import.postprocess
        assert_equal('true', zzb1.value)
        assert_equal(false, zzb2.value)
      end
    end
  end
end
