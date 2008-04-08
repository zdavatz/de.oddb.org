#!/usr/bin/env ruby
# Import::Csv::TestProductInfos -- de.oddb.org -- 13.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/import/csv'
require 'flexmock'
require 'mechanize'
require 'stub/model'

module ODDB
  module Import
    module Csv
class TestProductInfos < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @var = File.expand_path('var', File.dirname(__FILE__))
    @path = File.expand_path('csv/products.csv', @data_dir) 
    @import = ProductInfos.new
    @errors = []
    c = ODDB.config
    c.data_dir = @data_dir
    c.var = @var
    c.credentials.store("product_infos", {
      "pop_server" => 'pop.server.com',
      "pop_user" => 'myuser',
      "pop_pass" => 'mypass',
      "pop_port" => 110,
    })
    Drugs::ActiveAgent.instances.clear
    Drugs::Composition.instances.clear
    Drugs::GalenicForm.instances.clear
    Drugs::Part.instances.clear
    Drugs::Package.instances.clear
    Drugs::Part.instances.clear
    Drugs::Product.instances.clear
    Drugs::Sequence.instances.clear
    Drugs::Substance.instances.clear
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
  def test_import
    agent = setup_search "result.html"
    ODDB.logger = flexmock('logger')
    ODDB.logger.should_receive(:error).and_return { |type, block|
      mesg = block.call
      #puts mesg
      @errors.push mesg
    }
    ODDB.logger.should_ignore_missing

    package1 = Drugs::Package.new
    package1.add_code(Util::Code.new(:cid, "8999084", 'DE'))
    part1 = Drugs::Part.new
    package1.add_part(part1)
    package1.save
    sequence1 = Drugs::Sequence.new
    package1.sequence = sequence1
    product1 = Drugs::Product.new
    sequence1.product = product1

    package2 = Drugs::Package.new
    package2.add_code(Util::Code.new(:cid, "8999552", 'DE'))
    package2.add_code(Util::Code.new(:prescription, true, 'DE'))
    package2.save
    sequence2 = Drugs::Sequence.new
    package2.sequence = sequence2
    product2 = Drugs::Product.new
    sequence2.product = product2
    company = Business::Company.new
    product2.company = company

    package3 = Drugs::Package.new
    package3.add_code(Util::Code.new(:cid, "8999575", 'DE'))
    package3.save
    sequence3 = Drugs::Sequence.new
    package3.sequence = sequence3
    product3 = Drugs::Product.new
    sequence3.product = product3

    package4 = Drugs::Package.new
    package4.add_code(Util::Code.new(:cid, "8999612", 'DE'))
    package4.add_code(Util::Code.new(:prescription, false, 'DE'))
    part4 = Drugs::Part.new
    part4.size = 1
    package4.add_part(part4)
    package4.save
    substance4 = Drugs::Substance.new
    substance4.name.de = 'Furosemid'
    substance4.save
    agent4 = Drugs::ActiveAgent.new(substance4, 10000)
    composition4 = Drugs::Composition.new
    composition4.add_active_agent(agent4)
    sequence4 = Drugs::Sequence.new
    sequence4.add_composition(composition4)
    package4.sequence = sequence4
    product4 = Drugs::Product.new
    sequence4.product = product4

    package5 = Drugs::Package.new
    package5.add_code(Util::Code.new(:cid, "8999629", 'DE'))
    package5.add_code(Util::Code.new(:prescription, false, 'DE'))
    package5.sequence = sequence4
    part5 = Drugs::Part.new
    part5.size = 1
    package5.add_part(part5)
    package5.save
    agent5 = Drugs::ActiveAgent.new(substance4, 25000)
    composition5 = Drugs::Composition.new
    composition5.add_active_agent(agent5)
    sequence5 = Drugs::Sequence.new
    sequence5.add_composition(composition5)
    package5.sequence = sequence5
    sequence5.product = product4

    package6 = Drugs::Package.new
    package6.add_code(Util::Code.new(:cid, "8999635", 'DE'))
    package6.add_code(Util::Code.new(:prescription, false, 'DE'))
    package6.sequence = sequence4
    part6 = Drugs::Part.new
    part6.size = 1
    package6.add_part(part6)
    package6.save
    package6.sequence = sequence5

    package7 = Drugs::Package.new
    package7.add_code(Util::Code.new(:cid, "2092271", 'DE'))
    package7.add_code(Util::Code.new(:prescription, false, 'DE'))
    agent7 = Drugs::ActiveAgent.new(substance4, 25000)
    composition7 = Drugs::Composition.new
    composition7.add_active_agent(agent7)
    sequence7 = Drugs::Sequence.new
    sequence7.add_composition(composition7)
    sequence7.product = product4
    package7.sequence = sequence7
    part7 = Drugs::Part.new
    part7.size = 1
    package7.add_part(part7)
    package7.save

    package8 = Drugs::Package.new
    package8.add_code(Util::Code.new(:cid, "2093187", 'DE'))
    package8.add_code(Util::Code.new(:prescription, false, 'DE'))
    package8.sequence = sequence7
    part8 = Drugs::Part.new
    part8.size = 1
    package8.add_part(part8)
    package8.save

    input = open(@path)
    @import.import(input, :import_known => true ,
                          :import_unknown => true, :agent => agent)

    assert_equal 9, Drugs::Package.instances.size
    assert_equal([ package1, package2, package3, package4, package5, 
                   package6, package7, package8], 
                   Drugs::Package.instances[0,8])
    assert_equal(false, package1.code(:prescription).value)
    assert_equal('Aframed GmbH', product1.company.name.de)
    assert_equal(false, package2.code(:prescription).value)
    assert_equal(company, product2.company)
    assert_equal(true, package3.code(:prescription).value)
    assert_equal('Heumann Ph GmbH & Co. KG', product3.company.name.de)
    assert_equal(true, package4.code(:prescription).value)
    assert_equal('Heumann Ph GmbH & Co. KG', product4.company.name.de)
    assert_equal(product3.company, product4.company)

    assert_equal(Drugs::Dose.new(50, 'ml'), part1.quantity)

    assert_equal(String, package2.name.de.class)
    assert_equal("Biotin Hermes 2,5 mg Tabletten", package2.name.de)


    assert_equal(20, part4.size)
    assert_equal([Drugs::Dose.new(500, 'mg')], sequence4.doses)
    assert_equal(2, sequence4.packages.size)
    assert_equal([package4, package5], sequence4.packages)
    assert_equal([Drugs::Dose.new(250, 'mg')], package6.sequence.doses)

    assert_equal(5, part7.multi)
    assert_equal(10, part7.size)

    assert_equal(40, part8.multi)
    assert_equal(5, part8.size)
    assert_equal(Drugs::Dose.new(20, 'ml'), part8.quantity)
  end
  def test_import_row__tropfen
    package = Drugs::Package.new
    package.add_code(Util::Code.new(:cid, "7448548", 'DE'))
    part = Drugs::Part.new
    package.add_part(part)
    package.save
    sequence = Drugs::Sequence.new
    package.sequence = sequence
    product = Drugs::Product.new
    sequence.product = product

    src = <<-EOS
"7448548";"TRAMADOL Tropfen";"Rezeptpflichtig";"10";"ml";"Tropfen";9.3193;9.3193;"1";"WINTHROP ARZNEIM.GMBH";"nein";"nein"
    EOS
    row = CSV.parse(src, ';').first
    @import.import_row(row)

    assert_equal(nil, part.multi)
    assert_equal(1, part.size)
    assert_equal(Drugs::Dose.new(10, 'ml'), part.quantity)
  end
  def test_import_row__tropfen__size
    package = Drugs::Package.new
    package.add_code(Util::Code.new(:cid, "7448554", 'DE'))
    part = Drugs::Part.new
    package.add_part(part)
    package.save
    sequence = Drugs::Sequence.new
    package.sequence = sequence
    product = Drugs::Product.new
    sequence.product = product

    src = <<-EOS
"7448554";"TRAMADOL Tropfen";"Rezeptpflichtig";"3X10";"ml";"Tropfen";12.0168;12.0168;"1";"WINTHROP ARZNEIM.GMBH";"nein";"nein"
    EOS
    row = CSV.parse(src, ';').first
    @import.import_row(row)

    assert_equal(nil, part.multi)
    assert_equal(3, part.size)
    assert_equal(Drugs::Dose.new(10, 'ml'), part.quantity)
  end
  def test_import_unknown__create_product
    agent = setup_search "result.html"
    ODDB.logger = flexmock('logger')
    ODDB.logger.should_receive(:error).and_return { |type, block|
      mesg = block.call
      puts mesg
      @errors.push mesg
    }
    ODDB.logger.should_ignore_missing
    src = <<-EOS
"0225437";"AARANE N Dos.-Aerosol";"Rezeptpflichtig";"10";"ml";"Suspension";34.9832;34.9832;"1";"SANOFI-AVENTIS DT.GMBH";"nein";"nein"
    EOS
    row = CSV.parse(src, ';').first
    prod = @import.import_unknown(agent, '7448554', 'Aarane', row)
    assert_instance_of Drugs::Product, prod
    assert_equal "AARANE  SANOFI", prod.name.de
    assert_equal 1, prod.sequences.size
    seq = prod.sequences.first
    assert_instance_of Drugs::Sequence, seq
    assert_equal 1, seq.compositions.size
    assert !seq.fachinfo.empty?
    assert seq.patinfo.empty? # the mocked agent returns a fachinfo..
    comp = seq.compositions.first
    assert_instance_of Drugs::Composition, comp
    galform = comp.galenic_form
    assert_instance_of Drugs::GalenicForm, galform
    assert_equal 'Suspension', galform.description.de
    assert_equal 2, comp.active_agents.size
    agent1 = comp.active_agents.first 
    assert_instance_of Drugs::ActiveAgent, agent1
    assert_instance_of Drugs::Substance, agent1.substance
    assert_equal 'Reproterolhydrochlorid', agent1.substance.name.de
    assert_equal Drugs::Dose.new(0.5, 'mg'), agent1.dose
    agent2 = comp.active_agents.last
    assert_instance_of Drugs::ActiveAgent, agent2
    assert_instance_of Drugs::Substance, agent2.substance
    assert_equal 'Natriumcromoglicat (Ph.Eur.)', agent2.substance.name.de
    assert_equal Drugs::Dose.new(1, 'mg'), agent2.dose
    assert_equal 1, comp.parts.size
    part = comp.parts.first
    assert_instance_of Drugs::Part, part
    assert_equal 1, seq.packages.size
    pac = seq.packages.first
    assert_instance_of Drugs::Package, pac
    assert_equal [part], pac.parts
    assert_equal 1, part.size
    assert_equal Drugs::Dose.new(10, 'ml'), part.quantity
    assert_equal 'Suspension', part.unit.name.de
    assert_equal pac, part.package
    assert_equal comp, part.composition
  end
  def test_import_unknown__create_sequence
    agent = setup_search "result.html"
    ODDB.logger = flexmock('logger')
    ODDB.logger.should_receive(:error).and_return { |type, block|
      mesg = block.call
      puts mesg
      @errors.push mesg
    }
    ODDB.logger.should_ignore_missing
    src = <<-EOS
"0225437";"AARANE N Dos.-Aerosol";"Rezeptpflichtig";"10";"ml";"Suspension";34.9832;34.9832;"1";"SANOFI-AVENTIS DT.GMBH";"nein";"nein"
    EOS
    row = CSV.parse(src, ';').first
    product = Drugs::Product.new
    product.name.de = "AARANE  SANOFI"
    product.save
    prod = @import.import_unknown(agent, '7448554', 'Aarane', row)
    assert_equal product, prod

    assert_equal "AARANE  SANOFI", prod.name.de
    assert_equal 1, prod.sequences.size
    seq = prod.sequences.first
    assert_instance_of Drugs::Sequence, seq
    assert_equal 1, seq.compositions.size
    comp = seq.compositions.first
    assert_instance_of Drugs::Composition, comp
    galform = comp.galenic_form
    assert_instance_of Drugs::GalenicForm, galform
    assert_equal 'Suspension', galform.description.de
    assert_equal 2, comp.active_agents.size
    agent1 = comp.active_agents.first 
    assert_instance_of Drugs::ActiveAgent, agent1
    assert_instance_of Drugs::Substance, agent1.substance
    assert_equal 'Reproterolhydrochlorid', agent1.substance.name.de
    assert_equal Drugs::Dose.new(0.5, 'mg'), agent1.dose
    agent2 = comp.active_agents.last
    assert_instance_of Drugs::ActiveAgent, agent2
    assert_instance_of Drugs::Substance, agent2.substance
    assert_equal 'Natriumcromoglicat (Ph.Eur.)', agent2.substance.name.de
    assert_equal Drugs::Dose.new(1, 'mg'), agent2.dose
    assert_equal 1, comp.parts.size
    part = comp.parts.first
    assert_instance_of Drugs::Part, part
    assert_equal 1, seq.packages.size
    pac = seq.packages.first
    assert_instance_of Drugs::Package, pac
    assert_equal [part], pac.parts
    assert_equal 1, part.size
    assert_equal Drugs::Dose.new(10, 'ml'), part.quantity
    assert_equal 'Suspension', part.unit.name.de
    assert_equal pac, part.package
    assert_equal comp, part.composition
  end
  def test_import_unknown__create_package
    agent = setup_search "result.html"
    ODDB.logger = flexmock('logger')
    ODDB.logger.should_receive(:error).and_return { |type, block|
      mesg = block.call
      puts mesg
      @errors.push mesg
    }
    ODDB.logger.should_ignore_missing
    src = <<-EOS
"0225437";"AARANE N Dos.-Aerosol";"Rezeptpflichtig";"10";"ml";"Suspension";34.9832;34.9832;"1";"SANOFI-AVENTIS DT.GMBH";"nein";"nein"
    EOS
    row = CSV.parse(src, ';').first
    product = Drugs::Product.new
    product.name.de = "AARANE  SANOFI"
    sequence = Drugs::Sequence.new
    composition = Drugs::Composition.new
    sub1 = Drugs::Substance.new
    sub1.name.de = 'Reproterolhydrochlorid' 
    sub1.save
    act1 = Drugs::ActiveAgent.new sub1, Drugs::Dose.new(0.5, 'mg')
    act1.save
    composition.add_active_agent act1
    sub2 = Drugs::Substance.new
    sub2.name.de = 'Natriumcromoglicat (Ph.Eur.)' 
    sub2.save
    act2 = Drugs::ActiveAgent.new sub2, Drugs::Dose.new(1, 'mg')
    act2.save
    composition.add_active_agent act2
    galenic_form = Drugs::GalenicForm.new
    galenic_form.description.de = 'Suspension'
    galenic_form.save
    composition.galenic_form = galenic_form
    composition.save
    sequence.add_composition composition
    sequence.product = product
    sequence.save
    product.save

    prod = @import.import_unknown(agent, '7448554', 'Aarane', row)

    assert_equal product, prod

    assert_equal "AARANE  SANOFI", prod.name.de
    assert_equal 1, prod.sequences.size
    seq = prod.sequences.first
    assert_equal sequence, seq

    assert_equal 1, seq.compositions.size
    comp = seq.compositions.first
    assert_equal composition, comp
    galform = comp.galenic_form
    assert_equal galenic_form, galform
    assert_equal 'Suspension', galform.description.de

    assert_equal 2, comp.active_agents.size
    agent1 = comp.active_agents.first 
    assert_equal act1, agent1
    assert_equal sub1, agent1.substance
    assert_equal 'Reproterolhydrochlorid', agent1.substance.name.de
    assert_equal Drugs::Dose.new(0.5, 'mg'), agent1.dose
    agent2 = comp.active_agents.last
    assert_equal act2, agent2
    assert_equal sub2, agent2.substance
    assert_equal 'Natriumcromoglicat (Ph.Eur.)', agent2.substance.name.de
    assert_equal Drugs::Dose.new(1, 'mg'), agent2.dose

    assert_equal 1, comp.parts.size
    part = comp.parts.first
    assert_instance_of Drugs::Part, part
    assert_equal 1, seq.packages.size
    pac = seq.packages.first
    assert_instance_of Drugs::Package, pac
    assert_equal [part], pac.parts
    assert_equal 1, part.size
    assert_equal Drugs::Dose.new(10, 'ml'), part.quantity
    assert_equal 'Suspension', part.unit.name.de
    assert_equal pac, part.package
    assert_equal comp, part.composition
  end
  def test_poll_message
    source = File.read(File.join(@data_dir, 'mail', 'csv.mail'))
    message = RMail::Parser.read(source)
    ProductInfos.extract_message(message) { |io|
      assert_instance_of(Zip::ZipInputStream, io)
    }
  end
  def test_download_latest
    backup = File.join(@var, 'mail')
    FileUtils.rm_r(backup) if(File.exist? backup)
    source = File.read(File.join(@data_dir, 'mail', 'csv.mail'))
    mail = flexmock('mail')
    mail.should_receive(:pop).times(1).and_return source
    mail.should_receive(:delete).times(1)
    session = flexmock('pop-session')
    session.should_receive(:each_mail).and_return { |block| block.call(mail) }
    flexstub(Net::POP3).should_receive(:start)\
      .and_return { |host, port, user, pass, block| 
      assert_equal('pop.server.com', host)
      assert_equal(110, port)
      assert_equal('myuser', user)
      assert_equal('mypass', pass)
      block.call(session) 
    }
    ProductInfos.download_latest { |io|
      assert_instance_of(Zip::ZipInputStream, io)
    }
    assert(File.exist?(backup))
    assert_equal(3, Dir.entries(backup).size)
  end
end
    end
  end
end
