#!/usr/bin/env ruby
# Selenium::TestFachinfo -- de.oddb.org -- 01.11.2007 -- hwyss@ywesee.com


$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'
require 'oddb/drugs'
require 'oddb/util'

module ODDB
  module Selenium
class TestFachinfo < Test::Unit::TestCase
  include Selenium::TestCase
  def setup
    Drugs::Package.instances.clear
    super
  end
  def setup_package(pzn='12345')
    product = Drugs::Product.new
    company = Business::Company.new
    company.name.de = 'Producer AG'
    product.company = company
    company.save
    sequence = Drugs::Sequence.new
    sequence.atc = Drugs::Atc.new('N04BB01')
    sequence.atc.name.de = 'Amantadin'
    ddd = Drugs::Ddd.new('O')
    ddd.dose = Drugs::Dose.new(5, 'mg')
    sequence.atc.add_ddd(ddd)
    sequence.product = product
    composition = Drugs::Composition.new
    composition.equivalence_factor = '44.6'
    sequence.add_composition(composition)
    substance = Drugs::Substance.new
    substance.name.de = "Amantadin"
    dose = Drugs::Dose.new(100, 'mg')
    active_agent = Drugs::ActiveAgent.new(substance, dose)
    composition.add_active_agent(active_agent)
    package = Drugs::Package.new
    code = Util::Code.new(:festbetragsstufe, 3, 'DE')
    package.add_code(code)
    code = Util::Code.new(:zuzahlungsbefreit, true, 'DE')
    package.add_code(code)
    code = Util::Code.new(:prescription, true, 'DE')
    package.add_code(code)
    code = Util::Code.new(:cid, pzn, 'DE')
    package.add_code(code)
    part = Drugs::Part.new
    part.composition = composition
    part.package = package
    part.size = 5
    unit = Drugs::Unit.new
    unit.name.de = 'Ampullen'
    part.unit = unit
    part.quantity = Drugs::Dose.new(20, 'ml')
    package.name.de = 'Amantadin by Producer'
    package.sequence = sequence
    package.add_price(Util::Money.new(6, :public, 'DE'))
    package.add_price(Util::Money.new(10, :festbetrag, 'DE'))
    package.save
    package
  end
  def setup_fachinfo
    document = Text::Document.new
    chapter = Text::Chapter.new('name')
    paragraph = Text::Paragraph.new
    paragraph.set_format("b")
    paragraph << "1. Bezeichnung"
    chapter.add_paragraph paragraph
    paragraph = Text::Paragraph.new
    paragraph << "Amantadin Product"
    chapter.add_paragraph paragraph
    document.add_chapter(chapter)
    chapter = Text::Chapter.new('composition')
    paragraph = Text::Paragraph.new
    paragraph.set_format("b")
    paragraph << "2. Zusammensetzung"
    chapter.add_paragraph paragraph
    table = Text::Table.new
    table << "Für Kinder"
    table.next_cell!
    table << "Für Erwachsene"
    table.next_row!
    table << "10 mg Amantadin pro Tablette"
    table.next_cell!
    table << "100 mg Amantadin pro Tablette"
    chapter.add_paragraph table
    document.add_chapter(chapter)
    chapter = Text::Chapter.new('packaging')
    paragraph = Text::Paragraph.new
    paragraph.set_format("b")
    paragraph << "6.1"
    paragraph.set_format()
    paragraph << " Behältnis"
    chapter.add_paragraph paragraph
    picture = Text::Picture.new('not empty...')
    flexmock(picture).should_receive(:path).and_return('/resources/oddb/logo.png')
    flexmock(picture).should_receive(:filename).and_return('logo.png')
    chapter.add_paragraph picture 
    document.add_chapter(chapter)
    document
  end
  def test_fachinfo
    package = setup_package
    package.fachinfo.de = setup_fachinfo
    open "/de/drugs/fachinfo/pzn/12345"
    assert_equal "DE - ODDB.org | Medikamente | Fachinformation | Amantadin by Producer | Open Drug Database", get_title
    assert is_text_present "1. Bezeichnung\nAmantadin Product"
  end
end
  end
end
