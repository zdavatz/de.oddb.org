#!/usr/bin/env ruby
# Import::Whocc::TestAtc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/config'
require 'oddb/import/whocc'
require 'mechanize'
require 'stub/model'

module ODDB
  module Drugs
    class Atc < Model
      simulate_database(:code)
    end
    class Ddd < Model
      simulate_database
    end
  end
  module Import
    module Whocc
class TestAtc < Test::Unit::TestCase
  def setup
    Drugs::Atc.instances.clear
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @path = File.expand_path('xml/ATC_2006.xml', @data_dir) 
    @import = Atc.new
  end
  def test_import
    assert_equal([], Drugs::Atc.instances)
    input = open(@path)
    @import.import(input) 
    assert_equal(23, Drugs::Atc.instances.size)
    atc = Drugs::Atc.instances.first
    expected = [ 'A', 'A01', 'A01A', 'A01AA', 'A01AA01', 'A01AA30',
      'A01AB', 'A01AB02', 'V', 'V01', 'V01A', 'V01AA', 'V01AA01',
      'V03', 'V03A', 'V03AB', 'V03AB01', 'V03AZ01', 'V04', 'V04C',
      'V04CC04', 'V04CD', 'V04CD05', ]
    codes = Drugs::Atc.instances.collect { |atc| atc.code }
    assert_equal(expected, codes)
    assert_equal('ALIMENTÄRES SYSTEM UND STOFFWECHSEL',
                 Drugs::Atc.instances.at(0).name.de)
    assert_equal('STOMATOLOGIKA',
                 Drugs::Atc.instances.at(1).name.de)
    assert_equal('Somatorelin',
                 Drugs::Atc.instances.at(22).name.de)

    # do it again, nothing should change
    input = open(@path)
    @import.import(input) 
    assert_equal(23, Drugs::Atc.instances.size)
    atc = Drugs::Atc.instances.first
    codes = Drugs::Atc.instances.collect { |atc| atc.code }
    assert_equal(expected, codes)
    assert_equal('ALIMENTÄRES SYSTEM UND STOFFWECHSEL',
                 Drugs::Atc.instances.at(0).name.de)
    assert_equal('STOMATOLOGIKA',
                 Drugs::Atc.instances.at(1).name.de)
    assert_equal('Somatorelin',
                 Drugs::Atc.instances.at(22).name.de)
  end
end
class TestDdd < Test::Unit::TestCase
  def setup
    Drugs::Atc.instances.clear
    Drugs::Ddd.instances.clear
    @data_dir = File.expand_path('data', File.dirname(__FILE__))
    @path = File.expand_path('xml/ATC_2006_ddd.xml', @data_dir) 
    @import = Ddd.new
  end
  def test_import
    assert_equal([], Drugs::Atc.instances)
    assert_equal([], Drugs::Ddd.instances)
    input = open(@path)
    @import.import(input) 
    assert_equal(2, Drugs::Atc.instances.size)
    assert_equal(3, Drugs::Ddd.instances.size)
    atc1 = Drugs::Atc.instances.at(0)
    atc2 = Drugs::Atc.instances.at(1)
    ddds = Drugs::Ddd.instances
    assert_equal(ddds[0,1], atc1.ddds)
    assert_equal(ddds[1,2], atc2.ddds)
    ddd1 = atc2.ddds.first
    ddd2 = atc2.ddds.last
    assert_equal('O', ddd1.administration)
    assert_equal(Drugs::Dose.new(7, 'mg'), ddd1.dose)
    assert_equal('mikrokristall. Substanz', ddd1.comment)
    assert_equal(atc2, ddd1.atc)
    assert_equal('O', ddd2.administration)
    assert_equal(Drugs::Dose.new(10, 'mg'), ddd2.dose)
    assert_nil(ddd2.comment)
    assert_equal(atc2, ddd2.atc)
    codes = Drugs::Atc.instances.collect { |atc| atc.code }

    # do it again, nothing should change
    input = open(@path)
    @import.import(input) 
    assert_equal(2, Drugs::Atc.instances.size)
    assert_equal(3, Drugs::Ddd.instances.size)
    atc1 = Drugs::Atc.instances.at(0)
    atc2 = Drugs::Atc.instances.at(1)
    ddds = Drugs::Ddd.instances
    assert_equal(ddds[0,1], atc1.ddds)
    assert_equal(ddds[1,2], atc2.ddds)
    ddd1 = atc2.ddds.first
    ddd2 = atc2.ddds.last
    assert_equal('O', ddd1.administration)
    assert_equal(Drugs::Dose.new(7, 'mg'), ddd1.dose)
    assert_equal('mikrokristall. Substanz', ddd1.comment)
    assert_equal(atc2, ddd1.atc)
    assert_equal('O', ddd2.administration)
    assert_equal(Drugs::Dose.new(10, 'mg'), ddd2.dose)
    assert_nil(ddd2.comment)
    assert_equal(atc2, ddd2.atc)
    codes = Drugs::Atc.instances.collect { |atc| atc.code }
  end
end
class TestGuidelines < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    Drugs::Atc.instances.clear
    @import = Guidelines.new
    @html_path = File.expand_path('data/html/whocc', 
                                  File.dirname(__FILE__))
  end
  def setup_page(url, html)
    response = {'content-type' => 'text/html'}
    WWW::Mechanize::Page.new(url, response, html, 200)
  end
  def teardown
    ODDB.config.credentials = {}
    super
  end
  def test_login
    ODDB.config.credentials = {
      'whocc' => {'username' => 'tester', 'password' => 'secret'},
    }
    url = 'http://www.whocc.no/atcddd/database/index.php'
    html = File.read(File.join(@html_path, 'login.html'))
    page = setup_page(url, html)
    agent = flexmock('Mechanize')
    agent.should_receive(:get).with(url).and_return(page)
    agent.should_receive(:submit).with(WWW::Mechanize::Form)\
      .and_return { |form|
      assert_equal('tester', form.username)
      assert_equal('secret', form.password)
    }
    @import.login(agent)
  end
  def test_login__no_credentials
    agent = flexmock('Mechanize')
    assert_raises(RuntimeError) {
      @import.login(agent)
    }
  end
  def test_import_code__A
    url = "http://www.whocc.no/atcddd/database/index.php?query=A&showdescription=yes"
    html = File.read(File.join(@html_path, 'A.html'))
    page = setup_page(url, html)
    agent = flexmock('Mechanize')
    agent.should_receive(:get).with(url).times(1).and_return(page)
    @import.import_code(agent, @import.codes.shift)
    assert_equal(['A'], @import.codes.visited)
    assert_equal(%w{B C D G H J L M N P R S V A01 A02 A03 A04 A05 A06 
                    A07 A08 A09 A10 A11 A12 A13 A14 A15 A16},
                    @import.codes.queue)
    assert_equal(1, Drugs::Atc.instances.size)
    atc = Drugs::Atc.instances.first
    assert_equal('A', atc.code)
    assert_equal('Alimentary Tract and Metabolism', atc.name.en)
    assert_equal(nil, atc.guidelines.en)
    assert_equal(nil, atc.ddd_guidelines.en)
  end
  def test_import_code__A03
    url = "http://www.whocc.no/atcddd/database/index.php?query=A03&showdescription=yes"
    html = File.read(File.join(@html_path, 'A03.html'))
    page = setup_page(url, html)
    agent = flexmock('Mechanize')
    agent.should_receive(:get).with(url).times(1).and_return(page)
    @import.codes.queue.clear.push('A03')
    @import.import_code(agent, @import.codes.shift)
    assert_equal(['A03'], @import.codes.visited)
    assert_equal(%w{A A03A A03B A03C A03D A03E A03F}, 
                 @import.codes.queue)
    assert_equal(1, Drugs::Atc.instances.size)
    atc = Drugs::Atc.instances.first
    assert_equal('A03', atc.code)
    assert_equal('Drugs for Functional Gastrointestinal Disorders', 
                 atc.name.en)
    expected = <<-EOS
A major part of the preparations in this group are combined preparations. Preparations containing e.g. analgesics and antispasmodics could be classified either in this group or in N02 - Analgesics. Combinations of psycholeptics and antispasmodics could be classified in A03 or in N05 - Psycholeptics etc. The main indication for the use of the combination will, together with the relative effect of the active components, decide the classification. In the treatment of pain caused by spasms, the spasmolytic component must be judged as more important than the analgesic component. Accordingly, analgesic/antispasmodic combinations should be classified in A03 if the main effect of the preparation is the antispasmodic action.
Combined preparations are classified in:


A03C - Antispasmodics in combination with psycholeptics
A03D - Antispasmodics in combination with analgesics
A03E - Antispasmodics and anticholinergics in combination with other drugs

Antispasmodics, which are used specifically in the urogenital tractus, are classified in G04BD - Urinary antispasmodics.

    EOS
    assert_equal(expected, atc.guidelines.en)
    expected = <<-EOS
The DDD is equal for different routes of administration (oral, parenteral or rectal) of the same compound and is based on the oral dose. 
    EOS
    assert_equal(expected.chop, atc.ddd_guidelines.en)
  end
  def test_import_code__A03AB
    url = "http://www.whocc.no/atcddd/database/index.php?query=A03AB&showdescription=yes"
    html = File.read(File.join(@html_path, 'A03AB.html'))
    page = setup_page(url, html)
    agent = flexmock('Mechanize')
    agent.should_receive(:get).with(url).times(1).and_return(page)
    @import.codes.queue.clear.push('A03AB')
    @import.import_code(agent, @import.codes.shift)
    assert_equal(['A03AB'], @import.codes.visited)
    assert_equal(%w{A A03 A03A}, @import.codes.queue)
    assert_equal(22, Drugs::Atc.instances.size)
    atc = Drugs::Atc.instances.first
    assert_equal('A03AB', atc.code)
    assert_equal('Synthetic Anticholinergics, Quaternary Ammonium Compounds', 
                 atc.name.en)
    expected = <<-EOS
Plain preparations containing glycopyrronium are classified in this group. Preparations containing glycopyrronium in combination with neostigmine are classified in N07AA51. Trospium see G04BD and A03DA.
    EOS
    assert_equal(expected.chop, atc.guidelines.en)
    assert_equal(nil, atc.ddd_guidelines.en)
    atc = Drugs::Atc.instances.at(1)
    assert_equal('A03AB01', atc.code)
    assert_equal('Benzilone', atc.name.en)
  end
  def test_import_code__C03
    url = "http://www.whocc.no/atcddd/database/index.php?query=C03&showdescription=yes"
    html = File.read(File.join(@html_path, 'C03.html'))
    page = setup_page(url, html)
    agent = flexmock('Mechanize')
    agent.should_receive(:get).with(url).times(1).and_return(page)
    @import.codes.queue.clear.push('C03')
    @import.import_code(agent, @import.codes.shift)
    assert_equal(['C03'], @import.codes.visited)
    assert_equal(%w{C C03A C03B C03C C03D C03E}, @import.codes.queue)
    assert_equal(1, Drugs::Atc.instances.size)
    atc = Drugs::Atc.instances.first
    assert_equal('C03', atc.code)
    assert_equal('Diuretics', atc.name.en)
    expected = <<-EOS
This group comprises diuretics, plain and in combination with potassium or other agents. Potassium-sparing agents are classified in C03D and C03E.

Combinations with digitalis glycosides, see C01AA.

Combinations with antihypertensives, see C02L - Antihypertensives and diuretics in combination.

Combinations with beta blocking agents, see C07B - C07D.

Combinations with calcium channel blockers, see C08.

Combinations with agents acting on the renin angiotensin system, see C09B and C09D.

    EOS
    assert_equal(expected, atc.guidelines.en)
    expected = <<-EOS
The DDDs for diuretics are based on monotherapy. Most diuretics are used both for the treatment of edema and hypertension in similar doses and the DDDs are therefore based on both indications.

The DDDs for combinations correspond to the DDD for the diuretic component, except for ATC group C03E, see comments under this level.
    EOS
    assert_equal(expected.chop, atc.ddd_guidelines.en)
  end
end
class TestCodeHandler < Test::Unit::TestCase
  def setup
    @handler = Guidelines::CodeHandler.new
  end
  def test_shift
    @handler.instance_variable_set('@queue', ['A', 'B'])
    assert_equal('A', @handler.shift)
    assert_equal(['A'], @handler.instance_variable_get('@visited'))
    assert_equal(['B'], @handler.instance_variable_get('@queue'))
  end
  def test_push
    @handler.instance_variable_set('@queue', ['A'])
    @handler.push('B')
    assert_equal(['A', 'B'], @handler.instance_variable_get('@queue'))
  end
  def test_push__visited
    @handler.instance_variable_set('@queue', ['A'])
    @handler.instance_variable_set('@visited', ['B'])
    @handler.push('B')
    assert_equal(['A'], @handler.instance_variable_get('@queue'))
  end
  def test_push__twice
    @handler.instance_variable_set('@queue', ['A', 'B'])
    @handler.push('B')
    assert_equal(['A', 'B'], @handler.instance_variable_get('@queue'))
  end
end
    end
  end
end
