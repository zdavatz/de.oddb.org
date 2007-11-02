#!/usr/bin/env ruby
# Import::TestPharmNet -- de.oddb.org -- 15.10.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'oddb/config'
require 'oddb/import/pharmnet'
#require 'hpricot'

module ODDB
  module Import
    module PharmNet
class TestFiParser < Test::Unit::TestCase
  def setup
    @importer = FiParser.new
    ODDB.config.var = File.expand_path('var', File.dirname(__FILE__))
  end
  def test_import__aspirin
    path = File.expand_path('data/rtf/pharmnet/aspirin.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = %w{default name composition galenic_form clinical indications
                  dosage counterindications precautions interactions pregnancy
                  driving_ability unwanted_effects overdose pharmacology
                  pharmacodynamics pharmacokinetics preclinicals pharmaceutic
                  excipients incompatibilities shelf_life storage packaging
                  company registration registration_date date sale_limitation
                  additional_information}
    assert_equal(expected, chapters.collect { |ch| ch.name })
    expected = "1.\tBezeichnung des Arzneimittels\nAspirin\302\256\nWirkstoff: Acetylsalicyls\303\244ure"
    assert_equal(expected, chapters.at(1).to_s)
    expected = <<-EOS
zusätzliche Angaben:
Bioverfügbarkeit
Eine im Jahr 1998/99 durchgeführte Bioverfügbarkeitsuntersuchung an 17 Probanden ergab für Aspirin in Bezug auf Acetylsalicylsäure- und Salicylsäurewerte die folgenden Ergebnisse:
                                                               Werte für Acetylsalicylsäure  Werte für Salicylsäure  
maximale Plasmakonzentration(Cmax) in μg/ml                    3,63 ± 1,94                   20,1 ± 1,25             
Zeitpunkt der maximalen Plasma-Konzentration (tmax) in h*      0.50(0,33 - 2)                2,0 (0,833 - 3,069      
Fläche unter der Konzentrations-Zeit-Kurve (AUC) in μg x h/ml  4,25 ± 1,53                   107 ± 1,30              
Angabe als geom. Mittelwerte Standardabweichung (* Angabe als Median und Streubreite)
    EOS
    assert_equal(expected.strip, chapters.last.to_s)
  end
  def test_import__omeprazol
    path = File.expand_path('data/rtf/pharmnet/omeprazol.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = %w{default name composition galenic_form clinical indications
                  dosage counterindications precautions interactions pregnancy
                  driving_ability unwanted_effects overdose pharmacology
                  pharmacodynamics pharmacokinetics preclinicals pharmaceutic
                  excipients incompatibilities shelf_life storage packaging 
                  disposal company registration registration_date date
                  sale_limitation }
    assert_equal(expected, chapters.collect { |ch| ch.name })
    expected = "11.\tVerschreibungsstatus/Apothekenpflicht\nVerschreibungspflichtig"
    assert_equal(expected, chapters.last.to_s)
  end
  def test_import__selegilin
    path = File.expand_path('data/rtf/pharmnet/selegilin.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = %w{default name composition galenic_form clinical indications
                  dosage counterindications precautions interactions pregnancy
                  driving_ability unwanted_effects overdose pharmacology
                  pharmacodynamics pharmacokinetics preclinicals pharmaceutic
                  excipients incompatibilities shelf_life storage packaging 
                  disposal company registration registration_date date
                  sale_limitation }
    assert_equal(expected, chapters.collect { |ch| ch.name })
    expected = "F a c h i n f o r m a t i o n"
    assert_equal(expected, chapters.at(0).to_s)
    expected = "1.\tBezeichnung des Arzneimittels\nSelegilin 5 Heumann\nTabletten mit 5 mg Selegilinhydrochlorid"
    assert_equal(expected, chapters.at(1).to_s)
    expected = "4.6\tAnwendung w\303\244hrend Schwangerschaft und Stillzeit\nAusreichende tierexperimentelle Untersuchungen oder Erfahrungen \303\274ber den Einfluss von Selegilinhydrochlorid auf die Schwangerschaft und Stillzeit beim Menschen liegen nicht vor. Daher darf Selegilinhydrochlorid in der Schwangerschaft und Stillzeit nicht angewendet werden."
    assert_equal(expected, document.chapter("pregnancy").to_s)
    expected = <<-EOS
4.7\tAuswirkungen auf die Verkehrst\303\274chtigkeit und das Bedienen von Maschinen
Die bei der kombinierten Einnahme von Selegilinhydrochlorid mit Levodopa enthaltenen Arzneimittel k\303\266nnen zentralnerv\303\266se Nebenwirkungen wie z.B. M\303\274digkeit, Benommenheit, Schwindel, vereinzelt Verwirrtheit oder Sehst\303\266rungen ausl\303\266sen. Deshalb kann auch bei bestimmungsgem\303\244\303\237em Gebrauch von Selegilinhydrochlorid das Reaktionsverm\303\266gen so weit ver\303\244ndert werden, dass die F\303\244higkeit zur aktiven Teilnahme am Stra\303\237enverkehr oder zum Bedienen von Maschinen unabh\303\244ngig von der zu behandelnden Grunderkrankung weiter beeintr\303\244chtigt wird. Ferner sind T\303\244tigkeiten, die mit erh\303\266hter Absturz- oder Unfallgefahr einhergehen, zu meiden. Dies gilt in verst\303\244rktem Ma\303\237e im Zusammenwirken mit Alkohol.
    EOS
    assert_equal(expected.strip, document.chapter("driving_ability").to_s)
    expected = "7.\tPharmazeutischer Unternehmer\nHEUMANN PHARMA\nGmbH & Co. Generica KG\nS\303\274dwestpark 50\n90449 N\303\274rnberg\nTelefon/Telefax: 0700 4386 2667 "
    assert_equal(expected, document.chapter("company").to_s)
    expected = "11.\tVerschreibungsstatus/Apothekenpflicht \nVerschreibungspflichtig"
    assert_equal(expected, chapters.last.to_s)
  end
end
class TestPharmNet < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @importer = FachInfo.new
    ODDB.config.var = File.expand_path('var', File.dirname(__FILE__))
  end
  def test_import_rtf
    url = "http://gripsdb.dimdi.de/amispb/doc/2136914-20050504/OBFM654A78B701C54FC6.rtf"
    path = File.expand_path('data/rtf/pharmnet/selegilin.rtf', 
                            File.dirname(__FILE__))
    agent = flexmock('agent')
    file = flexmock('file')
    agent.should_receive(:get).with(url).and_return(file)
    file.should_receive(:body).and_return { File.read path }
    document = @importer.import_rtf(agent, url)
  end
end
    end
  end
end
