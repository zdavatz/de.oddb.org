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
    class TestDimdi < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @config = flexstub(ODDB.config)
        @var = File.expand_path('var', File.dirname(__FILE__))
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @xls_dir = File.join(@var, 'xls')
        FileUtils.rm_r(@xls_dir) if(File.exist?(@xls_dir))
        @config.should_receive(:var).and_return(@var)
      end
      def test_current_date
        path = File.join(@data_dir, 'html', 'dimdi_index.html')
        assert_equal(Date.new(2007), Dimdi.current_date(path))
      end
      def test_download_latest__only_once
        today = Date.new(2006,10)
        file = "liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        path = File.join(@xls_dir, file)
        arch = File.join(@xls_dir, sprintf("2006.10.01-%s", file))
        zuzahlung = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        zuzahlung_uri = flexmock('Zuzahlungsbefreiung-URI')
        zuzahlung_uri.should_receive(:open)\
          .times(2).and_return { 
          StringIO.new("download_latest-io-read")
        }
        uriparse = flexstub(URI)
        uriparse.should_receive(:parse).with(zuzahlung)\
          .times(2).and_return(zuzahlung_uri)
        Dimdi.download_latest(zuzahlung, today) { |fh|
          assert_equal('download_latest-io-read', fh.read)
        }
        assert(File.exist?(path))
        assert(File.exist?(arch))
        Dimdi.download_latest(zuzahlung, today) { |fh|
          flunk("should not be called again")
        }
      end
    end
    module Dimdi
class TestGalenicForm < Test::Unit::TestCase
  def setup
    Drugs::GalenicForm.instances.clear
    Drugs::GalenicGroup.instances.clear
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @path = File.expand_path('xls/darform_010706.xls', @data_dir) 
    @import = GalenicForm.new
  end
  def setup_form(name)
    form = Drugs::GalenicForm.new
    form.description.de = name
    form.save
    form
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
  def test_postprocess
    form1 = setup_form('Tabletten')
    form2 = setup_form('Filmtabletten')
    form3 = setup_form('Retardtabletten')
    form4 = setup_form('Retardkapseln')
    @import.postprocess
    assert_equal(5, Drugs::GalenicGroup.instances.size)
    group1 = Drugs::GalenicGroup.find_by_name('Tabletten')
    assert_equal(group1, form1.group)
    assert_equal(group1, form2.group)
    group2 = Drugs::GalenicGroup.find_by_name('Retard-Tabletten')
    assert_equal(group2, form3.group)
    assert_equal(group2, form4.group)
  end
end
class TestProduct < Test::Unit::TestCase
  def setup
    Drugs::Product.instances.clear
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @path = File.expand_path('xls/fb010706.xls', @data_dir) 
    @import = Product.new
  end
  def test_import_base_data
    tabl = Drugs::GalenicForm.new
    tabl.description.de = 'Kapseln'
    tabl.add_code(Util::Code.new(:galenic_form, 'KAPS', 'DE'))
    tabl.save
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
    names = Drugs::Product.instances.collect { |inst|
      inst.name.de
    }
    assert_equal(11, Drugs::Product.instances.size, names.inspect)
    expected = [ u("Piroxicam Ratio"), u("Amoxicillin Ratio"),
      u("Buscopan Aca"), u("Aquaphoril Aca"), u("Aspirin Aca"),
      u("Sibelium Aca"), u("Capto Merckdura"), 
      u("Aknefug/Mino Wolff"), u("Ribofluor"), u("Dexa Ct"), 
      u("Madopar Emra"), ]
    assert_equal(expected, names)
    pr = Drugs::Product.instances.first
    assert_equal(1, pr.sequences.size)
    seq = pr.sequences.first
    assert_equal(1, seq.compositions.size)
    comp = seq.compositions.first
    assert_equal(1.1, comp.equivalence_factor)
    assert_equal(1, comp.active_agents.size)
    agent = comp.active_agents.first
    assert_equal(sub1, agent.substance)
    assert_equal(2, seq.packages.size)
    pack = seq.packages.first
    assert_equal(34.25, pack.price(:public, 'DE'))
    assert_equal(34.28, pack.price(:festbetrag, 'DE'))
    code = pack.code(:festbetragsstufe, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal(2, code.value)
    code = pack.code(:festbetragsgruppe, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal(u('9'), code.value)
    assert_equal(1, pack.parts.size)
    assert_equal(100, pack.size)
    part = pack.parts.first
    assert_instance_of(Drugs::Unit, part.unit)
    assert_equal(u('Tabletten'), part.unit.name.de)
    code = pack.code(:cid, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal("649", code.value)

    pack = seq.packages.last
    code = pack.code(:cid, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal("114568", code.value)

    pr = Drugs::Product.instances.at(1)
    seq = pr.sequences.first
    assert_equal(atc, seq.atc)

    pr = Drugs::Product.instances.at(2)
    seq = pr.sequences.first
    pack = seq.packages.first
    assert_equal('2A', pack.code(:festbetragsgruppe).value)

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
    assert_equal(1, pr.sequences.size)
    seq = pr.sequences.first
    assert_equal(1, seq.compositions.size)
    comp = seq.compositions.first
    assert_equal(1.1, comp.equivalence_factor)
    assert_equal(1, comp.active_agents.size)
    agent = comp.active_agents.first
    assert_equal(sub1, agent.substance)
    assert_equal(2, seq.packages.size)
    pack = seq.packages.first
    assert_equal(34.25, pack.price(:public, 'DE'))
    assert_equal(34.28, pack.price(:festbetrag, 'DE'))
    code = pack.code(:festbetragsstufe, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal(2, code.value)
    code = pack.code(:festbetragsgruppe, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal(u('9'), code.value)
    assert_equal(1, pack.parts.size)
    assert_equal(100, pack.size)
    part = pack.parts.first
    assert_instance_of(Drugs::Unit, part.unit)
    assert_equal(u('Tabletten'), part.unit.name.de)
    code = pack.code(:cid, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal("649", code.value)

    pack = seq.packages.last
    code = pack.code(:cid, 'DE')
    assert_instance_of(Util::Code, code)
    assert_equal("114568", code.value)

    pr = Drugs::Product.instances.at(1)
    seq = pr.sequences.first
    assert_equal(atc, seq.atc)

    pr = Drugs::Product.instances.at(2)
    seq = pr.sequences.first
    pack = seq.packages.first
    assert_equal('2A', pack.code(:festbetragsgruppe).value)

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
class TestSubstance < Test::Unit::TestCase
  def setup
    Drugs::Substance.instances.clear
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @path = File.expand_path('xls/wirkkurz_010406.xls', @data_dir) 
    @import = Substance.new
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
class TestZuzahlungsBefreiung < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    Drugs::Package.instances.clear
    Drugs::Product.instances.clear
    Drugs::Substance.instances.clear
    Business::Company.instances.clear
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @path = File.expand_path('xls/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls', @data_dir) 
    @import = ZuzahlungsBefreiung.new
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
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    assert_equal(atc, sequence.atc)
    assert_equal([sequence], atc.sequences)
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
    assert_equal(1, Business::Company.instances.size)
    comp = Business::Company.instances.first
    assert_equal('Ratiopharm GmbH', comp.name.de)

    # do it again, nothing should change
    existing.code(:zuzahlungsbefreit).value = false
    input = open(@path)
    report = @import.import(input)
    assert_instance_of(Array, report)
    assert_equal(1, Drugs::Product.instances.size)
    assert_equal([product], Drugs::Product.instances)
    assert_equal(atc, sequence.atc)
    assert_equal([sequence], atc.sequences)
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    assert_equal(atc, sequence.atc)
    assert_equal([sequence], atc.sequences)
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
    assert_equal(1, Business::Company.instances.size)
    comp = Business::Company.instances.first
    assert_equal('Ratiopharm GmbH', comp.name.de)
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
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    assert_equal(atc, sequence.atc)
    assert_equal([sequence], atc.sequences)
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
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    assert_equal(atc, sequence.atc)
    assert_equal([sequence], atc.sequences)
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
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    assert_equal(atc, sequence.atc)
    assert_equal([sequence], atc.sequences)
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
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    assert_equal(atc, sequence.atc)
    assert_equal([sequence], atc.sequences)
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
  def test_import_active_agent
    sequence = Drugs::Sequence.new
    composition = Drugs::Composition.new
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = u"Fluvoxamin-Hydrogenmaleat"
    active_agent = Drugs::ActiveAgent.new(substance, 50)
    composition.add_active_agent(active_agent)
    row = [ 
     "Fluvoxamin", "0227488", "FLUVOHEXAL 50MG FILMTABL",
     "Filmtabletten", 20, "St", "HEXAL AG", "15.21", 
     "Fluvoxamin hydrogenmaleat", 50, "mg",
    ].collect { |data|
      mock = flexmock(data.to_s)
      mock.should_receive(:to_s).and_return(data.to_s)
      mock
    }
    @import.import_active_agent(sequence, row, 8)
    assert_equal([active_agent], composition.active_agents)
  end
  def test_import_active_agent__correct_dose
    sequence = Drugs::Sequence.new
    composition = Drugs::Composition.new
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = u"Fluvoxamin hydrogenmaleat"
    active_agent = Drugs::ActiveAgent.new(substance, nil)
    composition.add_active_agent(active_agent)
    row = [ 
     "Fluvoxamin", "0227488", "FLUVOHEXAL 50MG FILMTABL",
     "Filmtabletten", 20, "St", "HEXAL AG", "15.21", 
     "Fluvoxamin hydrogenmaleat", 50, "mg",
    ].collect { |data|
      mock = flexmock(data.to_s)
      mock.should_receive(:to_s).and_return(data.to_s)
      mock
    }
    @import.import_active_agent(sequence, row, 8)
    assert_equal([active_agent], composition.active_agents)
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
end
