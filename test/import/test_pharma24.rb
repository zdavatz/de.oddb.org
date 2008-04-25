#!/usr/bin/env ruby
# Import::TestPharma24 -- de.oddb.org -- 21.04.2008 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'mechanize'
require 'oddb/import/pharma24'
require 'stub/model'

module ODDB
  module Import
class TestPharma24 < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @importer = Pharma24.new
  end
  def setup_page(agent, url, name=nil)
    dir = File.expand_path('data/html/pharma24', File.dirname(__FILE__))
    uri = URI.parse url
    name ||= File.basename uri.path
    path = File.join(dir, name)
    agent.pluggable_parser.parser("text/html").new(
      URI.parse("http://www.apotheke-online-internet.de" + uri.path),
      {'content-type'=>'text/html'}, File.read(path), 200
    ) { |parser| parser.mech = agent }
  end
  def test_search
    agent = flexmock(WWW::Mechanize.new)
    url = 'http://www.apotheke-online-internet.de/advanced_search_result.php?keywords=1337397'
    agent.should_receive(:get).with(url).and_return { 
      setup_page agent, url, '1337397.html'
    }
    urls = @importer.search agent, '1337397'
    expected = [
      {
        :name              => 'BB NEWS Plus Schwangerschafs Stabtest',
        :code_prescription => false,
        :size              => '1',
        :unit              => 'St',
        :unitname          => 'Test',
        :price_public      => 7.8,
        :company           => 'DR D LOHMANN PH.& MED.',
        :url               => 'http://www.apotheke-online-internet.de/b/bb/p1337397_bb-news-plus-schwangerschafs-stabtest.html',
      }
    ]
    assert_equal expected, urls
  end
  def test_get_alphabetical
    agent = flexmock(WWW::Mechanize.new)
    url = 'http://www.apotheke-online-internet.de/ac.html'
    page = setup_page agent, url
    agent.should_receive(:get).with(url).and_return(page)  
    2.upto(77) { |num|
      url = "http://www.apotheke-online-internet.de/a/ac-page-#{num}.html"
      page = setup_page agent, url
      agent.should_receive(:get).with(url).and_return(page)  
    }
    urls = @importer.get_alphabetical agent, 'a', 'c'
    assert_equal 2285, urls.size
  end
  def test_update_package
    pac = Drugs::Package.new
    pac.add_code Util::Code.new(:cid, 1337397, 'DE')
    pac.sequence = seq = Drugs::Sequence.new
    seq.product = Drugs::Product.new
    agent = flexmock(WWW::Mechanize.new)
    url = 'http://www.apotheke-online-internet.de/advanced_search_result.php?keywords=1337397'
    agent.should_receive(:get).with(url).and_return { 
      setup_page agent, url, '1337397.html'
    }
    @importer.update_package(agent, pac)
    price = pac.price :public
    assert_instance_of Util::Money, price
    assert_equal 7.8, price
    assert_equal :pharma24, pac.data_origin(:price_public)
    assert_equal 'BB NEWS Plus Schwangerschafs Stabtest', pac.name.de
    code = pac.code :prescription
    assert_instance_of Util::Code, code
    assert_equal false, code.value
    part = pac.parts.first
    assert_equal 1, part.size
    unit = part.unit
    assert_instance_of Drugs::Unit, unit
    assert_equal 'Test', unit.name.de
    assert_nil part.quantity
    company = pac.company
    assert_instance_of Business::Company, company
    assert_equal 'Dr D Lohmann Ph.  &  Med.', company.name.de
  end
end
  end
end
