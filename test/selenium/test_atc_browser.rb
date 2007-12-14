#!/usr/bin/env ruby
# Selenium::TestAtcBrowser -- de.oddb.org -- 14.12.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'selenium/unit'
require 'stub/model'

module ODDB
  module Selenium
class TestAtcBrowser < Test::Unit::TestCase
  include Selenium::TestCase
  def test_atc_browser
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
    flexstub(atc6).should_receive(:packages).and_return(['nonempty'])
    open "/de/drugs/atc_browser"

    assert_equal 'DE - ODDB.org | Medikamente | ATC-Browser | Open Drug Database', 
                 get_title

    assert is_text_present('Nervensystem (N)')
    assert is_element_present('link=Nervensystem (N)')
    assert !is_text_present('Antiparkinsonmittel (N04)')
    assert !is_element_present('link=ddd')

    click 'link=Nervensystem (N)'
    wait_for_page_to_load "30000"

    assert_equal 'DE - ODDB.org | Medikamente | ATC-Browser | Open Drug Database', 
                 get_title
    assert is_text_present('Nervensystem (N)')
    assert is_element_present('link=Nervensystem (N)')
    assert is_text_present('Antiparkinsonmittel (N04)')
    assert is_element_present('link=Antiparkinsonmittel (N04)')
    assert is_element_present('link=WHO-DDD')
    ## opened because they are single children:
    assert is_text_present("Dopaminerge Mittel (N04B)")
    assert is_element_present("link=Dopaminerge Mittel (N04B)")
    assert is_text_present("Dopa und Dopa-Derivate (N04BA)")
    assert is_element_present("link=Dopa und Dopa-Derivate (N04BA)")
    assert is_text_present("Levodopa und Decarboxylasehemmer (N04BA02)")
    assert is_text_present("Levodopa, Decarboxylasehemmer und COMT-Hemmer (N04BA03)")
    ## has no packages
    assert !is_element_present("link=Levodopa und Decarboxylasehemmer (N04BA02)")
    ## has packages
    assert is_element_present("link=Levodopa, Decarboxylasehemmer und COMT-Hemmer (N04BA03)")


    click 'link=Antiparkinsonmittel (N04)'
    wait_for_page_to_load "30000"
    assert_equal 'DE - ODDB.org | Medikamente | ATC-Browser | Open Drug Database', 
                 get_title
    assert is_text_present('Nervensystem (N)')
    assert is_element_present('link=Nervensystem (N)')
    assert is_text_present('Antiparkinsonmittel (N04)')
    assert !is_element_present('link=Antiparkinsonmittel (N04)')
    assert is_element_present('link=WHO-DDD')
    ## opened because they are single children:
    assert is_text_present("Dopaminerge Mittel (N04B)")
    assert is_element_present("link=Dopaminerge Mittel (N04B)")
    assert is_text_present("Dopa und Dopa-Derivate (N04BA)")
    assert is_element_present("link=Dopa und Dopa-Derivate (N04BA)")
    assert is_text_present("Levodopa und Decarboxylasehemmer (N04BA02)")
    assert is_text_present("Levodopa, Decarboxylasehemmer und COMT-Hemmer (N04BA03)")
    ## has no packages
    assert !is_element_present("link=Levodopa und Decarboxylasehemmer (N04BA02)")
    ## has packages
    assert is_element_present("link=Levodopa, Decarboxylasehemmer und COMT-Hemmer (N04BA03)")

  end
end
  end
end
