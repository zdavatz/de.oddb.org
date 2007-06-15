#!/usr/bin/env ruby
# Export::Xls::Test -- de.oddb.org -- 16.03.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))
$: << File.expand_path('..', File.dirname(__FILE__))

require 'drb'
require 'flexmock'
require 'test/unit'
require 'oddb/export/xls'
require 'stub/model'

module ODDB
  module Export
    module Xls
class TestComparisonDeCh < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @export = ComparisonDeCh.new
    flexstub(Currency).should_receive(:rate).with('EUR', 'CHF')\
      .and_return(1.6)
  end
  def setup_package(name="Amantadin by Producer", atccode='N04BB01')
    product = Drugs::Product.new
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.product = product
    atc = Drugs::Atc.new(atccode)
    atc.name.de = 'Amantadin'
    ddd = Drugs::Ddd.new('O')
    ddd.dose = Drugs::Dose.new(10, 'mg')
    atc.add_ddd(ddd)
    sequence.atc = atc
    composition = Drugs::Composition.new
    galform = Drugs::GalenicForm.new
    galform.description.de = 'Tropfen'
    composition.galenic_form = galform
    grp = Drugs::GalenicGroup.new('Tropfen')
    grp.administration = 'O'
    galform.group = grp
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = 'Amantadin'
    dose = Drugs::Dose.new(100, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    composition.add_active_agent(active_agent)
    package = Drugs::Package.new
    code = Util::Code.new(:cid, '12345', 'DE')
    package.add_code(code)
    code = Util::Code.new(:festbetragsstufe, 3, 'DE')
    package.add_code(code)
    code = Util::Code.new(:festbetragsgruppe, 4, 'DE')
    package.add_code(code)
    code = Util::Code.new(:zuzahlungsbefreit, true, 'DE')
    package.add_code(code)
    part = Drugs::Part.new
    part.package = package
    part.size = 5
    part.composition = composition
    unit = Drugs::Unit.new
    unit.name.de = 'Ampullen'
    part.unit = unit
    part.quantity = Drugs::Dose.new(20, 'ml')
    package.name.de = name
    package.sequence = sequence
    package.add_price(Util::Money.new(6, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.save
    package
  end
  def setup_remote_package(name, uid='55555', price=12, ikscat='B')
    rpackage = flexmock('Remote Package')
    rpackage.should_receive(:barcode).and_return("7680#{uid}0012")
    rpackage.should_receive(:name_base).and_return(name)
    rpackage.should_receive(:price_public).and_return {
      price
    }
    rpackage.should_receive(:ikscat).and_return(ikscat)
    rpackage.should_receive(:sl_entry).and_return(true)
    rpackage.should_receive(:comparable_size)\
      .and_return(Drugs::Dose.new(100, 'ml'))
    rpackage.should_receive(:__drbref).and_return(uid)
    rcompany = flexmock('Remote Company')
    rpackage.should_receive(:company).and_return(rcompany)
    rcompany.should_receive(:name).and_return('Producer (Schweiz) AG')
    ratc = flexmock('Remote Atc Class')
    rpackage.should_receive(:atc_class).and_return(ratc)
    ratc.should_receive(:code).and_return('N04BB01')
    ratc.should_receive(:de).and_return('Amantadine')
    ragent = flexmock('Remote ActiveAgent')
    rpackage.should_receive(:active_agents).and_return([ragent])
    rsubstance = flexmock('Remote Substance')
    ragent.should_receive(:dose).and_return(Drugs::Dose.new(100, 'mg'))
    ragent.should_receive(:substance).and_return(rsubstance)
    rsubstance.should_receive(:de).and_return('Amantadinum')
    rgalform = flexmock('Remote Galenic Form')
    rpackage.should_receive(:galenic_form).and_return(rgalform)
    rgalform.should_receive(:de).and_return('Tropfen')
    rgroup = flexmock('Remote Galenic Group')
    rgroup.should_receive(:de).and_return('Unbekannt')
    rgalform.should_receive(:galenic_group).and_return(rgroup)
    rpackage.should_ignore_missing
    rpackage
  end
  def test_export
    remote = flexmock('remote')
    pack = setup_package
    rpack = setup_remote_package('Remotadin')
    remote.should_receive(:remote_each_package).and_return { |block|
      block.call(rpack)
    }
    drb = DRb.start_service('druby://localhost:0', remote)
    book = flexmock('workbook')
    book.should_receive(:add_format).with(Format)
    book.should_ignore_missing
    flexstub(Spreadsheet::Excel).should_receive(:new).and_return(book)
    sheet = flexmock('worksheet')
    book.should_receive(:add_worksheet).with('Preisvergleich')\
      .times(1).and_return(sheet)
    sheet.should_receive(:write).with(0,0, Array, Format).times(1)

    expected = [ "Amantadin by Producer (Remotadin)", "100 ml", "8.68",
                 "Producer AG (Producer (Schweiz) AG)", "12345",
                 "7680555550012", "Tropfen", "100 mg", 
                 "Amantadin (Amantadinum)", "N04BB01", "B", "SL", 
                 "-3.32", "-27.66%", "1.00" ]
    sheet.should_receive(:write).with(1,0, Array).times(1)\
      .and_return { |row, col, cells|
      assert_equal(expected, cells)
    }
    @export.export(drb.uri, '')
  end
end
    end
  end
end
