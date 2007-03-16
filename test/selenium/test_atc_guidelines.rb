#!/usr/bin/env ruby
# Selenium::TestAtcGuidelines -- de.oddb.org -- 16.03.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'

module ODDB
  module Selenium
class TestAtcGuidelines < Test::Unit::TestCase
  include Selenium::TestCase
  def test_guidelines
    atc1 = Drugs::Atc.new('N04BA02')
    atc1.name.de = 'Levodopa und Decarboxylasehemmer'
    ddd = Drugs::Ddd.new('O')
    ddd.dose = Drugs::Dose.new(0.6, 'g')
    atc1.add_ddd(ddd)
    atc1.save
    atc2 = Drugs::Atc.new('N04BA')
    atc2.name.de = 'Dopa und Dopa-Derivate'
    atc2.guidelines.en = <<-EOS
Combinations with decarboxylase inhibitors and other dopaminergic agents are classified here.
    EOS
    atc2.ddd_guidelines.en = <<-EOS
The DDD for the combination of levodopa and decarboxylase inhibitor is based on the content of levodopa, see ATC index.
    EOS
    atc2.save
    atc3 = Drugs::Atc.new('N04B')
    atc3.name.de = 'Dopaminerge Mittel'
    atc3.save
    atc4 = Drugs::Atc.new('N04')
    atc4.name.de = 'Antiparkinsonmittel'
    atc4.guidelines.en = <<-EOS
This group comprises preparations used in the treatment of Parkinson's disease and related conditions, including drug-induced parkinsonism.
    EOS
    atc4.ddd_guidelines.en = <<-EOS
The DDDs are based on recommended doses for the long-term treatment of symptoms of Parkinson's disease.
No separate DDDs are established for oral depot formulations.
    EOS
    atc4.save
    atc5 = Drugs::Atc.new('N')
    atc5.name.de = 'Nervensystem'
    atc5.save
    atc6 = Drugs::Atc.new('N04BA03')
    atc6.name.de = 'Levodopa, Decarboxylasehemmer und COMT-Hemmer'
    atc6.save
    open "/de/drugs/ddd/code/N04BA02"

    assert_equal 'DE - ODDB.org | Medikamente | Tagesdosis | N04BA02 | Open Drug Database', 
                 get_title
    assert is_text_present('N - Nervensystem')
    assert is_text_present('N04 - Antiparkinsonmittel')
    assert is_text_present(atc4.guidelines.en)
    assert is_text_present(atc4.ddd_guidelines.en)
    assert is_text_present('N04B - Dopaminerge Mittel')
    assert is_text_present('N04BA - Dopa und Dopa-Derivate')
    assert is_text_present(atc2.guidelines.en)
    assert is_text_present(atc2.ddd_guidelines.en)
    assert is_text_present('N04BA02 - Levodopa und Decarboxylasehemmer')
    assert is_text_present('Oral')

    click 'link=N04BA'
    wait_for_page_to_load "30000"
    assert_equal 'DE - ODDB.org | Medikamente | Tagesdosis | N04BA | Open Drug Database', 
                 get_title
    assert is_text_present('N - Nervensystem')
    assert is_text_present('N04 - Antiparkinsonmittel')
    assert is_text_present(atc4.guidelines.en)
    assert is_text_present(atc4.ddd_guidelines.en)
    assert is_text_present('N04B - Dopaminerge Mittel')
    assert is_text_present('N04BA - Dopa und Dopa-Derivate')
    assert is_text_present(atc2.guidelines.en)
    assert is_text_present(atc2.ddd_guidelines.en)
    assert !is_text_present('N04BA02 - Levodopa und Decarboxylasehemmer')
    assert !is_text_present('Oral')
  end
end
  end
end
