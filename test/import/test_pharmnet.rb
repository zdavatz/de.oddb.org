#!/usr/bin/env ruby
# Import::TestPharmNet -- de.oddb.org -- 15.10.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'oddb/business/company'
require 'oddb/config'
require 'oddb/drugs/active_agent'
require 'oddb/drugs/galenic_form'
require 'oddb/drugs/sequence'
require 'oddb/drugs/substance'
require 'oddb/import/pharmnet'
require 'mechanize'
require 'stub/model'

module ODDB
  module Import
    module PharmNet
class TestFiParser < Test::Unit::TestCase
  def setup
    @importer = FiParser.new 'term is unimportant here'
    ODDB.config.var = File.expand_path('var', File.dirname(__FILE__))
  end
  def test_import__ace_hemmer
    path = File.expand_path('data/rtf/pharmnet/ace_hemmer_ratio.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "name", "sale_limitation", "composition",
                 "substance_group", "active_agents", "excipients",
                 "indications", "counterindications", "unwanted_effects",
                 "interactions", "precautions", "incompatibilities", "dosage",
                 "application", "overdose", "pharmacology", "toxicology",
                 "pharmacokinetics", "bioavailability", "other_advice",
                 "shelf_life", "storage", "packaging", "date", "company",
                 "producer"]
    assert_equal(expected, chapters.collect { |ch| ch.name })
  end
  def test_import__amlodipin
    path = File.expand_path('data/rtf/pharmnet/amlodipin.rtf', 
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
    expected = "Wortlaut der f\303\274r die Fachinformation vorgesehenen Angaben\nFachinformation"
    assert_equal(expected, chapters.at(0).to_s)
    expected = "1.\tBezeichnung der Arzneimittel\nAmlodipin [besilat] - 1 A Pharma 5 mg Tabletten\nAmlodipin [besilat] - 1 A Pharma 7,5 mg Tabletten\nAmlodipin [besilat] - 1 A Pharma 10 mg Tabletten"
    assert_equal(expected, chapters.at(1).to_s)
    expected = "4.6\tSchwangerschaft und Stillzeit\nSchwangerschaft\nEs liegen keine hinreichenden Daten f\303\274r die Anwendung von Amlodipin bei Schwangeren vor. \nTierexperimentelle Studien haben Reproduktionstoxizit\303\244t bei hohen Dosen gezeigt (siehe Abschnitt 5.3). Das potentielle Risiko f\303\274r den Menschen ist unbekannt. Amlodipin darf w\303\244hrend der Schwangerschaft nicht angewendet werden, es sei denn, der therapeutische Nutzen \303\274berwiegt deutlich das potentielle Risiko einer Behandlung.\nStillzeit\nEs ist nicht bekannt, ob Amlodipin in die Muttermilch \303\274bergeht. Es wird geraten, w\303\244hrend der Behandlung mit Amlodipin abzustillen."
    assert_equal(expected, document.chapter("pregnancy").to_s)
    expected = "11.\tVerkaufsabgrenzung\nVerschreibungspflichtig"
    assert_equal(expected, chapters.last.to_s)
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
  def test_import__claversal
    path = File.expand_path('data/rtf/pharmnet/claversal.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = ["default", "name", "sale_limitation", "composition",
                "substance_group", "active_agents", "excipients",
                "indications", "counterindications", "unwanted_effects",
                "interactions", "precautions", "incompatibilities", "dosage",
                "application", "overdose", "pharmacology", "toxicology",
                "pharmacokinetics", "bioavailability", "other_advice",
                "shelf_life", "storage", "packaging", "date", "company"]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    chapter = chapters.at(-7)
    picts = chapter.paragraphs.select { |par| par.is_a? Text::Picture }
    assert_equal 3, picts.size, "Oh, dear - imagemagick won't convert wmf-files.."
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
Die bei der kombinierten Einnahme von Selegilinhydrochlorid mit Levodopa enthaltenen Arzneimittel k\303\266nnen zentralnerv\303\266se Nebenwirkungen wie z. B. M\303\274digkeit, Benommenheit, Schwindel, vereinzelt Verwirrtheit oder Sehst\303\266rungen ausl\303\266sen. Deshalb kann auch bei bestimmungsgem\303\244\303\237em Gebrauch von Selegilinhydrochlorid das Reaktionsverm\303\266gen so weit ver\303\244ndert werden, dass die F\303\244higkeit zur aktiven Teilnahme am Stra\303\237enverkehr oder zum Bedienen von Maschinen unabh\303\244ngig von der zu behandelnden Grunderkrankung weiter beeintr\303\244chtigt wird. Ferner sind T\303\244tigkeiten, die mit erh\303\266hter Absturz- oder Unfallgefahr einhergehen, zu meiden. Dies gilt in verst\303\244rktem Ma\303\237e im Zusammenwirken mit Alkohol.
    EOS
    assert_equal(expected.strip, document.chapter("driving_ability").to_s)
    expected = "7.\tPharmazeutischer Unternehmer\nHEUMANN PHARMA\nGmbH & Co. Generica KG\nS\303\274dwestpark 50\n90449 N\303\274rnberg\nTelefon/Telefax: 0700 4386 2667 "
    assert_equal(expected, document.chapter("company").to_s)
    expected = "11.\tVerschreibungsstatus/Apothekenpflicht \nVerschreibungspflichtig"
    assert_equal(expected, chapters.last.to_s)
  end
end
class TestImport < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    ODDB.config.var = File.expand_path('var', File.dirname(__FILE__))
    @importer = Import.new
    @errors = []
    ODDB.logger = flexmock('logger')
    ODDB.logger.should_receive(:error).and_return { |type, block|
      msg = block.call
      puts msg
      @errors.push msg
    }
    ODDB.logger.should_ignore_missing
  end
  def setup_search(resultfile='empty_result.html')
    agent = flexmock(WWW::Mechanize.new)
    setup_agent(agent, resultfile, :get)
    setup_agent(agent, resultfile, :submit) { |form, button| 
      form.action 
    }
    setup_agent(agent, resultfile, :click) { |link| link.href }
    agent
  end
  def setup_agent(agent, resultfile, symbol, &block)
    dir = File.expand_path('data/html/pharmnet', File.dirname(__FILE__))
    agent.should_receive(symbol).and_return { |argument, *data|
      if(block)
        argument = block.call(argument, *data)
      end
      name = case argument
             when "http://www.pharmnet-bund.de/dynamic/de/am-info-system/index.html"
               'index.html'
             when "http://gripsdb.dimdi.de/websearch/servlet/Gate#__DEFANCHOR__"
               'gate.html'
             when "/websearch/servlet/FlowController/AcceptFZK?uid=000002"
               'search.html'
             when "/websearch/servlet/FlowController/DisplaySearchForm?uid=000002"
               'search_filtered.html'
             when "/websearch/servlet/FlowController/Search?uid=000002"
               (@resultfiles ||= []).shift || resultfile
             when "http://gripsdb.dimdi.de/websearch/servlet/FlowController/DisplayTitles?index=1&uid=000002"
               'paged_result_2.html'
             when "/websearch/servlet/FlowController/Documents-display"
               (@displayfiles ||= []).shift || 'display.html'
             when %r{/amispb/doc}
               '../../rtf/pharmnet/aspirin.rtf'
             when /display_.*.html/
               argument
             else
               flunk "encountered unknown path: #{argument}"
             end
      path = File.join(dir, name)
      uri = URI.parse argument
      agent.pluggable_parser.parser("text/html").new(
        URI.parse("http://www.pharmnet-bund.de" + uri.path),
        {'content-type'=>'text/html'}, File.read(path), 200
      ) { |parser| parser.mech = agent }
    }
  end
  def test_get_search_form
    agent = setup_search
    form = @importer.get_search_form(agent)
    assert_instance_of(WWW::Mechanize::Form, form)
    assert_equal("/websearch/servlet/FlowController/Search?uid=000002", 
                 form.action)
    radio = form.radiobuttons.find { |b| b.name == "WFTYP" && b.value == "YES" }
    @importer.set_fi_only(form)
    assert_equal(true, radio.checked)
    field = form.field('term')
    assert_instance_of(WWW::Mechanize::Field, field)

    ## if the sequence has incomplete active_agents, get all results
    @importer.set_fi_only(form, "NO_RESTRICTION")
    assert_equal(false, radio.checked)
    radio = form.radiobuttons.find { |b| 
      b.name == "WFTYP" && b.value == "NO_RESTRICTION" }
    assert_equal(true, radio.checked)
  end
  def test_import_rtf
    url = "http://gripsdb.dimdi.de/amispb/doc/2136914-20050504/OBFM654A78B701C54FC6.rtf"
    path = File.expand_path('data/rtf/pharmnet/selegilin.rtf', 
                            File.dirname(__FILE__))
    agent = flexmock('agent')
    file = flexmock('file')
    spath = File.join(ODDB.config.var, 
                      'rtf', 'pharmnet', 'OBFM654A78B701C54FC6.rtf')
    file.should_receive(:save).with(spath)
    agent.should_receive(:get).with(url).and_return(file)
    file.should_receive(:body).and_return { File.read path }
    document = @importer.import_rtf(:fachinfo, agent, url, 'selegilin')
    assert_instance_of Text::Document, document
    assert_equal url, document.source
  end
  def test_result_page__empty_result
    agent = setup_search
    form = @importer.get_search_form(agent)
    page = @importer.result_page(form, 'Aar O S')
    assert_instance_of WWW::Mechanize::Page, page
    result = @importer.extract_result agent, page
    assert result.empty?
  end
  def test_result_page
    agent = setup_search "result.html"
    form = @importer.get_search_form(agent)
    page = @importer.result_page(form, 'Aarane')
    assert_instance_of WWW::Mechanize::Page, page
    result = @importer.extract_result agent, page
    assert_equal(1, result.size)
    expected = [{
      :data => [ "AARANE N", 
                 "Suspension mit Treibmittel", 
                 "Sanofi-Aventis Deutschland GmbH" ], 
      :href => "/websearch/servlet/FlowController/Documents-display?uid=000002&docId=1"
    }]
    assert_equal expected, result
  end
  def test_result_page__paged
    agent = setup_search "paged_result_1.html"
    form = @importer.get_search_form(agent)
    page = @importer.result_page(form, 'Aspirin')
    assert_instance_of WWW::Mechanize::Page, page
    result = @importer.extract_result agent, page
    assert_equal(18, result.size)
    expected = {
      :data=> [ "Aspirin", "Tablette", "Bayer Vital GmbH" ],
      :href=> "/websearch/servlet/FlowController/Documents-display?uid=000002&docId=1"
    }
    assert_equal expected, result.first
    expected = {
      :data=> [ "Aspirin-Colfarit 100mg", 
                "magensaftresistente Tablette", 
                "Bayer Vital GmbH"],
      :href=> "/websearch/servlet/FlowController/Documents-display?uid=000002&docId=18"
    }
    assert_equal expected, result.last
  end
  def test_get_details
    agent = setup_search "result.html"
    form = @importer.get_search_form(agent)
    page = @importer.result_page(form, 'Aarane')
    result = @importer.extract_result agent, page
    page = @importer.get_details agent, page, result.first
    assert_instance_of WWW::Mechanize::Page, page
    details = @importer.extract_details page
    expected = {
      :patinfo  => "/amispb/doc/2007/08/15/2103159/OBFM262E63A401C7DE6A.rtf",
      :fachinfo => "/amispb/doc/2007/08/15/2103159/OBFM2F47BD1E01C7DE6A.rtf",
      :composition=> [
        { :dose => Drugs::Dose.new(0.5, "mg"), :ask_nr => "", 
          :substance => "Reproterolhydrochlorid" },
        { :dose => Drugs::Dose.new(1, "mg"), :ask_nr => "", 
          :substance => "Natriumcromoglicat (Ph.Eur.)" }
      ],
      :date_fachinfo => Date.new(2007,06,29),
      :date_patinfo => Date.new(2007,06,29),
      :registration => "3159.00.00",
    }
    assert_equal expected, details
  end
  def test_search__paged
    agent = setup_search "paged_result_1.html"
    result = @importer.search agent, 'Aspirin'
    assert_equal 18, result.size
    expected = {
      :patinfo=>"/amispb/doc/2007/08/15/2103159/OBFM262E63A401C7DE6A.rtf",
      :fachinfo=>"/amispb/doc/2007/08/15/2103159/OBFM2F47BD1E01C7DE6A.rtf",
      :composition=> [
        { :dose => Drugs::Dose.new(0.5, "mg"), :ask_nr => "", 
          :substance=>"Reproterolhydrochlorid" },
        { :dose => Drugs::Dose.new(1, "mg"), :ask_nr => "", 
          :substance=>"Natriumcromoglicat (Ph.Eur.)" }
      ],
      :data => ["Aspirin", "Tablette", "Bayer Vital GmbH"],
      :date_fachinfo => Date.new(2007,06,29),
      :date_patinfo => Date.new(2007,06,29),
      :registration=>"3159.00.00",
    }
    assert_equal expected, result.first
    expected = {
      :patinfo=>"/amispb/doc/2007/08/15/2103159/OBFM262E63A401C7DE6A.rtf",
      :fachinfo=>"/amispb/doc/2007/08/15/2103159/OBFM2F47BD1E01C7DE6A.rtf",
      :composition=> [
        { :dose => Drugs::Dose.new(0.5, "mg"), :ask_nr => "", 
          :substance=>"Reproterolhydrochlorid" },
        { :dose => Drugs::Dose.new(1, "mg"), :ask_nr => "", 
          :substance=>"Natriumcromoglicat (Ph.Eur.)" }
      ],
      :data=> [ "Aspirin-Colfarit 100mg", 
                "magensaftresistente Tablette", 
                "Bayer Vital GmbH"],
      :date_fachinfo => Date.new(2007,06,29),
      :date_patinfo => Date.new(2007,06,29),
      :registration=>"3159.00.00",
    }
    assert_equal expected, result.last
  end
  def test_search__cached
    agent = setup_search "paged_result_1.html"
    result = @importer.search agent, 'Aspirin'
    agent2= flexmock(WWW::Mechanize.new)
    agent2.should_receive(:get).and_return { 
      raise "the search for aspirin should be cached" }
    agent2.should_receive(:submit).and_return { 
      raise "the search for aspirin should be cached" }
    agent2.should_receive(:click).and_return { 
      raise "the search for aspirin should be cached" }
    result2 = @importer.search agent2, 'aspirin'
    assert_equal result, result2
  end
  def test_search__unresponsive
    agent = setup_search "result.html"
    history = ["history"]
    flexmock(agent.cookie_jar).should_receive(:clear!).times(1)
    agent.should_receive(:history).times(1).and_return { history }
    result = @importer.search agent, 'Aspirin'
    assert_equal(0, result.size)
    assert_equal([], history)
    assert_equal(["Searched for 'aspirin' but got result for 'Arzneimittelname: Aarane' - creating new session"], 
                 @errors)
  end
  def test_process__no_suitable_fachinfo_found__no_active_agents
    @resultfiles = %w{empty_result.html result.html}
    agent = setup_search
    sequence = flexmock(Drugs::Sequence.new)
    sequence.should_receive(:name)\
      .and_return(Util::Multilingual.new(:de => 'Aar O S'))
    company = Business::Company.new
    company.name.de = 'Company'
    sequence.should_receive(:company).and_return flexmock(company)
    @importer.process agent, sequence
    assert sequence.fachinfo.empty?
  end
  def test_process__no_suitable_fachinfo_found
    @resultfiles = %w{empty_result.html result.html}
    agent = setup_search
    sequence = flexmock(Drugs::Sequence.new)
    sequence.should_receive(:name)\
      .and_return(Util::Multilingual.new(:de => 'Aar O S'))
    company = Business::Company.new
    company.name.de = 'Company'
    sequence.should_receive(:company).and_return flexmock(company)
    substance = Drugs::Substance.new
    substance.name.de = 'Acetylsalicylsäure'
    act = Drugs::ActiveAgent.new substance, 300
    sequence.should_receive(:active_agents).and_return [flexmock(act)]
    @importer.process agent, sequence
    assert sequence.fachinfo.empty?
  end
  def test_process__http_500
    agent = flexmock(WWW::Mechanize.new)
    agent.should_receive(:get).times(3).and_return { 
      raise "500 => Net::HTTPInternalServerError"
    }
    sequence = flexmock(Drugs::Sequence.new)
    sequence.should_receive(:name)\
      .and_return(Util::Multilingual.new(:de => 'Aarane'))
    ODDB.logger = flexmock('logger')
    ODDB.logger.should_ignore_missing
    assert_nothing_raised {
      @importer.process agent, sequence, :retry_unit => 1, :retries => 2
    }
  end
  def test_process
    agent = setup_search "result.html"
    sequence = flexmock(Drugs::Sequence.new)
    sequence.should_receive(:name)\
      .and_return(Util::Multilingual.new(:de => 'Aarane'))
    company = Business::Company.new
    company.name.de = 'Sanofi-Aventis Dt. GmbH'
    sequence.should_receive(:company).and_return flexmock(company)
    galform = Drugs::GalenicForm.new
    galform.description.de = 'Dosieraerosol'
    sequence.should_receive(:galenic_forms).and_return [flexmock(galform)]
    substance1 = Drugs::Substance.new
    substance1.name.de = 'Reproterolhydrochlorid'
    agent1 = Drugs::ActiveAgent.new substance1, 0.5, 'mg'
    substance2 = Drugs::Substance.new
    substance2.name.de = 'Natriumcromoglicat (Ph.Eur.)'
    agent2 = Drugs::ActiveAgent.new substance2, 0, 'mg'
    sequence.should_receive(:active_agents)\
      .and_return [flexmock(agent1), flexmock(agent2)]
    @importer.process agent, sequence, :repair => true
    assert !sequence.fachinfo.empty?

    # Agents should be corrected
    assert_equal(Drugs::Dose.new(1, 'mg'), agent2.dose)

    # Registration should be assigned
    assert_equal(sequence.code(:registration, 'EU'), '3159.00.00')
  end
  def test_process__many
    @displayfiles = %w{display2.html display3.html display1.html} * 6
    agent = setup_search "paged_result_1.html"
    sequence = flexmock(Drugs::Sequence.new)
    sequence.should_receive(:name)\
      .and_return(Util::Multilingual.new(:de => 'Aspirin Protect'))
    company = Business::Company.new
    company.name.de = 'Bayer Vital GmbH'
    sequence.should_receive(:company).and_return flexmock(company)
    galform = Drugs::GalenicForm.new
    galform.description.de = 'Tabletten, Magensaftresistent'
    sequence.should_receive(:galenic_forms).and_return [flexmock(galform)]
    substance = Drugs::Substance.new
    substance.name.de = 'Acetylsalicylsäure'
    act = Drugs::ActiveAgent.new substance, 300
    sequence.should_receive(:active_agents).and_return [flexmock(act)]
    @importer.process agent, sequence
    assert !sequence.fachinfo.empty?
  end
  def test_exclusive_permutation
    assert_equal([[[0,0]]], @importer.exclusive_permutation(1))
    assert_equal([[[0,0], [1,1]], [[1,0], [0,1]]], 
                 @importer.exclusive_permutation(2))
    assert_equal([ [[0,0], [1,1], [2,2]], 
                   [[0,0], [2,1], [1,2]],
                   [[1,0], [0,1], [2,2]],
                   [[1,0], [2,1], [0,2]],
                   [[2,0], [0,1], [1,2]],
                   [[2,0], [1,1], [0,2]], ], 
                 @importer.exclusive_permutation(3))
  end
  def test_ngram_similarity
    assert_in_delta(1.0, @importer.ngram_similarity('Tablette', 'tablette'),
                    0.00001)
    assert_in_delta(0.8, @importer.ngram_similarity('Tablette', 'Tabletten'),
                    0.00001)
    assert_in_delta(0.75, 
                    @importer.ngram_similarity('Tablette, magensaftresistent', 
                                               'magensaftresistente Tabletten'),
                    0.0001)
    assert_in_delta(0.18, 
                    @importer.ngram_similarity('Tablette, magensaftresistent', 
                                               'Brausetabletten'), 
                    0.01)
    assert_in_delta(0.666, 
                    @importer.ngram_similarity('Aspirin Protect', 
                                               'Aspirin protect 300mg'),
                    0.001)
    assert_in_delta(0.333,
                    @importer.ngram_similarity('Reproterol', 
                                               'Reproterolhydrochlorid'),
                    0.001)
    assert_in_delta(0.238,
                    @importer.ngram_similarity('Cromoglicin', 
                                               'Natriumcromoglicat (Ph.Eur.)'),
                    0.001)

  end
  def test_suitable_data
    data = {
      :data => ['ACE-Hemmer-ratiopharm 100', 'Tabletten', 'Ratiopharm GmbH'],
      :composition => []
    }
    comparison = ['Ace Hemmer Ratio', 'Tabletten', 'Ratiopharm']

    assert_not_nil @importer._suitable_data(data, comparison, 0)
  end
  def test_best_data__tramal
    agent = setup_search "result.html"
    page = agent.get '/display_tramal.html'

    sequence = flexmock(Drugs::Sequence.new)
    sequence.should_receive(:name)\
      .and_return(Util::Multilingual.new(:de => 'Tramal'))
    company = Business::Company.new
    company.name.de = 'Gruenenthal GmbH'
    sequence.should_receive(:company).and_return flexmock(company)
    galform = Drugs::GalenicForm.new
    galform.description.de = 'Injektionslösung'
    sequence.should_receive(:galenic_forms).and_return [flexmock(galform)]
    substance1 = Drugs::Substance.new
    substance1.name.de = 'Tramadol'
    agent1 = Drugs::ActiveAgent.new substance1, 100, 'mg'
    sequence.should_receive(:active_agents)\
      .and_return [flexmock(agent1)]

    details = @importer.extract_details page
    details.store :data, ['Tramal 100 mg', 'Injektionsl?sung', 'Gr?nenthal GmbH']
    assert_equal details, @importer.best_data(sequence, [details])

    relevance = @importer.composition_relevance([agent1], details)
    assert 1.25 < relevance, "Relevance #{relevance} should be > 1.25"
  end
end
class TestPiParser < Test::Unit::TestCase
  def setup
    ODDB.config.var = File.expand_path('var', File.dirname(__FILE__))
  end
  def test_import_pi__aarane
    @importer = PiParser.new 'Aarane'
    path = File.expand_path('data/rtf/pharmnet/aarane.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", 
                 "additional_information", "date", "personal" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
  end
  def test_import_pi__ace_hemmer
    @importer = PiParser.new 'ace-hemmer'
    path = File.expand_path('data/rtf/pharmnet/ace_hemmer_ratio.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", "date" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert_equal(13, document.chapter('indications').paragraphs.size)
  end
  def test_import_pi__ace_hemmer_comp
    @importer = PiParser.new 'Ace.Hemmer'
    path = File.expand_path('data/rtf/pharmnet/ace_hemmer_comp_ratio.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage",
                 "additional_information", "company", "date" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__acemetacin
    @importer = PiParser.new 'Acemetacin.Ct'
    path = File.expand_path('data/rtf/pharmnet/acemetacin.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", 
                 "additional_information", "company", "date" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__acemit
    @importer = PiParser.new 'Acemit'
    path = File.expand_path('data/rtf/pharmnet/acemit.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "packaging", "indications",
                 "counterindications", "precautions", "application", 
                 "unwanted_effects", "storage", "date", "additional_information" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__acerbon
    @importer = PiParser.new 'Acerbon'
    path = File.expand_path('data/rtf/pharmnet/acerbon.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", "date",
                 "additional_information" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__acetylcystein
    @importer = PiParser.new 'Acetylcystein'
    path = File.expand_path('data/rtf/pharmnet/acetylcystein.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", "date", 
                 "personal"  ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__aciclo
    @importer = PiParser.new 'Aciclo'
    path = File.expand_path('data/rtf/pharmnet/aciclo.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", 
                 "additional_information", "company", "date" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__aciclovir
    @importer = PiParser.new 'Aciclovir'
    path = File.expand_path('data/rtf/pharmnet/aciclovir.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", 
                 "additional_information", "company", "date", "personal" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__actrapid
    @importer = PiParser.new 'Actrapid'
    path = File.expand_path('data/rtf/pharmnet/actrapid.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "emergency", "unwanted_effects", "storage", 
                 "date" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert document.chapter('indications').paragraphs.size > 1
  end
  def test_import_pi__amlodipin
    @importer = PiParser.new 'amlodipin'
    path = File.expand_path('data/rtf/pharmnet/amlodipin.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", "date" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    expected = <<-EOS.strip
Amlodipin Dexcel 10 mg Tabletten
Wirkstoff: Amlodipinmaleat
Der arzneilich wirksame Bestandteil ist Amlodipinmaleat.
1 Tablette enth\303\244lt 10 mg Amlodipin (als Amlodipinmaleat).
Die sonstigen Bestandteile sind: Lactose-Monohydrat; Povidon K 30; Povidon K 90; mikrokristalline Cellulose; Crospovidon; Natriumstearylfumarat.
Amlodipin Dexcel 10 mg ist in Packungen mit 20, 50 und 
100 Tabletten erh\303\244ltlich.
    EOS
    assert_equal(expected, chapters.at(1).to_s)
    indications = <<-EOS.strip
1. \tWAS IST Amlodipin Dexcel 10 mg UND WOF\303\234R WIRD ES ANGEWENDET?
1.1\tAmlodipin Dexcel 10 mg ist ein Mittel zur Behandlung von Bluthochdruck und Engegef\303\274hl in der Brust (Angina pectoris).
1.2\tvon:
Dexcel Pharma GmbH
R\303\266ntgenstra\303\237e 1
63755 Alzenau
hergestellt von:
Losan Pharma GmbH 
Otto-Hahn-Stra\303\237e 13
79395 Neuenburg 
1.3\tAmlodipin Dexcel 10 mg wird angewendet
bei nicht organbedingtem Bluthochdruck (essentieller Hypertonie) und bei Belastung auftretender (chronischer) und im Ruhezustand auftretender (vasospastischer) Angina pectoris (Engegef\303\274hl in der Brust).
    EOS
    assert_equal(indications, chapters.at(2).to_s)
    unwanted = document.chapter('unwanted_effects') 
    assert_equal(unwanted, chapters.at(5))
  end
  def test_import_pi__aspirin
    @importer = PiParser.new 'aspirin'
    path = File.expand_path('data/rtf/pharmnet/aspirin.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", 
                 "additional_information", "packaging", "company", "date" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
  end
  def test_import_pi__baymycard
    @importer = PiParser.new 'Baymycard'
    path = File.expand_path('data/rtf/pharmnet/baymycard.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", "date", 
                 "additional_information", "personal" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
  end
  def test_import_pi__omeprazol
    @importer = PiParser.new 'omeprazol'
    path = File.expand_path('data/rtf/pharmnet/omeprazol.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", "date",
                 "additional_information", "personal" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
  end
  def test_import_pi__selegilin
    @importer = PiParser.new 'selegilin'
    path = File.expand_path('data/rtf/pharmnet/selegilin.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "indications", "precautions",
                 "application", "unwanted_effects", "storage", "date",
                 "additional_information", "personal" ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
  end
  def test_import_pi__valium
    @importer = PiParser.new 'valium'
    path = File.expand_path('data/rtf/pharmnet/valium.pi.rtf', 
                            File.dirname(__FILE__))
    document = nil
    File.open(path) { |fh|
      document = @importer.import(fh)
    }
    assert_instance_of(Text::Document, document)
    chapters = document.chapters
    expected = [ "default", "composition", "packaging", "indications", 
                 "counterindications", "precautions", "application",
                 "unwanted_effects", "storage", "date", ]
    assert_equal(expected, chapters.collect { |ch| ch.name })
    assert !/nebenwirkungen/i.match(chapters.at(1).to_s), 
           "'Nebenwirkungen' should not appear in Composition"
  end
end
    end
  end
end
