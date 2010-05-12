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
        assert_equal(Date.new(2010,4), Dimdi.current_date(path))
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
    @path = File.expand_path('xls/fb010708.xls', @data_dir) 
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
    assert_equal(14, Drugs::Product.instances.size, names.inspect)
    expected = [ "Piroxicam Ratioph Tabs", "Amoxicillin Rat Mg Fta",
      "Buscopan", "Aquaphoril Aca", "To Be Deleted", "Aspirin", "Sibelium",
      "Move The Package", "Capto Dura M", "Move The Sequence", "Aknefug Mino",
      "Ribofluor Mgml", "Dexa Ct Mg Tabletten", "Madopar" ]
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
    assert_equal(14, Drugs::Product.instances.size)
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
    end
  end
end
