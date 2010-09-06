#!/usr/bin/env ruby
# Import::TestGkv -- ch.oddb.org -- 17.08.2009 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'stub/model'
require 'oddb/import/gkv'
require 'oddb/config'
require 'oddb'

module ODDB
  module Import
class TestGkv < Test::Unit::TestCase
  include FlexMock::TestCase
  class Invalidator
    attr_reader :invalidated
    def initialize
      @invalidated = []
    end
    def invalidate *odba_ids
      @invalidated.concat odba_ids
    end
  end
  def setup
    Drugs::Atc.instances.clear
    Drugs::Package.instances.clear
    Drugs::Product.instances.clear
    Drugs::Sequence.instances.clear
    Drugs::Substance.instances.clear
    Business::Company.instances.clear
    @invalidator = Invalidator.new
    svc = DRb.start_service 'druby://localhost:0', @invalidator
    ODDB.config.server_url = svc.uri
    @import = Gkv.new
    dir = File.expand_path('var', File.dirname(__FILE__))
    ODDB.config.var = dir
    @pdf_dir = File.join dir, 'pdf/gkv'
    dir = File.expand_path('data', File.dirname(__FILE__))
    @html_dir = File.join dir, 'html/gkv'
    dir = File.expand_path 'data/txt/gkv', File.dirname(__FILE__)
    @path = File.join dir, 'gkv_p1.txt'
    ODDB.logger = flexmock(:logger)
    ODDB.logger.should_receive(:error).and_return do |gkv, block|
      assert_equal 'Gkv', gkv
      flunk block.call
    end
    super
  end
  def teardown
    FileUtils.rm_r @pdf_dir if File.exist?(@pdf_dir)
    super
  end
  def setup_page(url, html, mech=nil)
    response = {'content-type' => 'text/html'}
    Mechanize::Page.new(URI.parse(url), response, html, 200, mech)
  end
  def simulate_import
    handler = GkvHandler.new @import.method(:process_page)
    File.read(@path).each do |line|
      handler.send_flowing_data line
      handler.send_line_break
    end
    handler.send_page
    @import.postprocess
    @import.report
  end
  def test_latest_url
    agent = flexmock(Mechanize.new)
    url = 'https://www.gkv-spitzenverband.de/Befreiungsliste_Arzneimittel_Versicherte.gkvnet'
    path = File.join @html_dir, 'Befreiungsliste_Arzneimittel_Versicherte.gkvnet'
    page = setup_page url, File.read(path), agent
    agent.should_receive(:get).with(url).and_return(page)
    expected = 'https://www.gkv-spitzenverband.de/upload/Zuzahlungsbefreit_sort_Name_090815_8351.pdf'
    assert_equal expected, @import.latest_url(agent)
  end
  def test_download_latest
    called = false
    @import.download_latest @path do |fh|
      assert_instance_of(File, fh)
      called = true
    end
    assert called, "download_latest did not call block"
    @import.download_latest @path do |fh|
      flunk "download_latest should not call block, if files are identical"
    end
    assert true
  end
  def test_import
    existing = Drugs::Package.new
    existing.add_code(Util::Code.new(:cid, '4000741', 'DE'))
    existing.add_part(Drugs::Part.new)
    existing.save
    sequence = Drugs::Sequence.new
    product = Drugs::Product.new
    product.name.de = 'A product'
    existing.sequence = sequence
    sequence.product = product
    assert_nil(existing.code(:zuzahlungsbefreit))

    ## simulate a call to @import.import
    report = simulate_import

    assert_equal 2, @invalidator.invalidated.size
    assert_equal 2, @invalidator.invalidated.uniq.size

    assert_instance_of(Array, report)
    assert_equal(1, Drugs::Product.instances.size)
    assert_equal(true, Drugs::Product.instances.include?(product))
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    #assert_equal(1, sequence.compositions.size)
    #composition = sequence.compositions.first
    #assert_equal(2, composition.active_agents.size)
    #agent1 = composition.active_agents.at(0)
    #agent2 = composition.active_agents.at(1)
    #assert_equal('Allopurinol', agent1.substance.name.de)
    #assert_equal(Drugs::Dose.new(100, 'mg'), agent1.dose)
    #assert_equal('Benzbromaron', agent2.substance.name.de)
    #assert_equal(Drugs::Dose.new(20, 'mg'), agent2.dose)
    code = existing.code(:zuzahlungsbefreit)
    assert_instance_of(Util::Code, code)
    assert_equal(true, code.value)
    confirmed = @import.instance_variable_get('@confirmed_pzns')
    assert_equal(1, confirmed.size)
    #assert_equal(2, Business::Company.instances.size)
    #comp = Business::Company.instances.first
    #assert_equal('Ratiopharm GmbH', comp.name.de)

    # do it again, nothing should change
    existing.code(:zuzahlungsbefreit).value = false

    @invalidator.invalidated.clear
    ## simulate a call to @import.import
    report = simulate_import

    assert_equal 2, @invalidator.invalidated.size
    assert_equal 2, @invalidator.invalidated.uniq.size

    assert_instance_of(Array, report)
    assert_equal(1, Drugs::Product.instances.size)
    assert_equal(true, Drugs::Product.instances.include?(product))
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    #assert_equal(1, sequence.compositions.size)
    #composition = sequence.compositions.first
    #assert_equal(2, composition.active_agents.size)
    #agent1 = composition.active_agents.at(0)
    #agent2 = composition.active_agents.at(1)
    #assert_equal('Allopurinol', agent1.substance.name.de)
    #assert_equal(Drugs::Dose.new(100, 'mg'), agent1.dose)
    #assert_equal('Benzbromaron', agent2.substance.name.de)
    #assert_equal(Drugs::Dose.new(20, 'mg'), agent2.dose)
    code = existing.code(:zuzahlungsbefreit)
    assert_instance_of(Util::Code, code)
    assert_equal(true, code.value)
    confirmed = @import.instance_variable_get('@confirmed_pzns')
    assert_equal(1, confirmed.size)
    #assert_equal(2, Business::Company.instances.size)
    #comp = Business::Company.instances.first
    #assert_equal('Ratiopharm GmbH', comp.name.de)
  end
  def test_import__ml
    existing = Drugs::Package.new
    existing.add_code(Util::Code.new(:cid, '4000646', 'DE'))
    existing.add_part(Drugs::Part.new)
    existing.save
    sequence = Drugs::Sequence.new
    product = Drugs::Product.new
    product.name.de = 'A product'
    existing.sequence = sequence
    sequence.product = product
    assert_nil(existing.code(:zuzahlungsbefreit))
    report = simulate_import
    assert_instance_of(Array, report)
    assert_equal(1, Drugs::Product.instances.size)
    assert_equal(true, Drugs::Product.instances.include?(product))
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    #assert_equal(1, sequence.compositions.size)
    #composition = sequence.compositions.first
    #assert_equal(1, composition.active_agents.size)
    #agent1 = composition.active_agents.at(0)
    #assert_equal('Amoxicillin-3-Wasser', agent1.substance.name.de)
    #assert_equal(Drugs::Dose.new(287, 'mg'), agent1.dose)
    code = existing.code(:zuzahlungsbefreit)
    assert_instance_of(Util::Code, code)
    assert_equal(true, code.value)
    assert_equal(1, existing.parts.size)
    part = existing.parts.first
    assert_equal(6, part.size)
    assert_equal('0.5 ml', part.quantity.to_s)

    # do it again, nothing should change
    report = simulate_import
    assert_instance_of(Array, report)
    assert_equal(1, Drugs::Product.instances.size)
    assert_equal(true, Drugs::Product.instances.include?(product))
    assert_equal(1, product.sequences.size)
    sequence = product.sequences.first
    #assert_equal(1, sequence.compositions.size)
    #composition = sequence.compositions.first
    #assert_equal(1, composition.active_agents.size)
    #agent1 = composition.active_agents.at(0)
    #assert_equal('Amoxicillin-3-Wasser', agent1.substance.name.de)
    #assert_equal(Drugs::Dose.new(287, 'mg'), agent1.dose)
    code = existing.code(:zuzahlungsbefreit)
    assert_instance_of(Util::Code, code)
    assert_equal(true, code.value)
    assert_equal(1, existing.parts.size)
    part = existing.parts.first
    assert_equal(6, part.size)
    assert_equal('0.5 ml', part.quantity.to_s)
  end
  def test_postprocess
    product = Drugs::Product.new
    product.name.de = 'Product 100% Company'
    product.save
    company = Business::Company.new
    company.name.de = 'Company AG'
    company.save
    @import.postprocess
    assert_equal(company, product.company)
  end
  def test_postprocess__comp
    product = Drugs::Product.new
    product.name.de = 'Product 100% Producer Comp'
    product.save
    company = Business::Company.new
    company.name.de = 'Producer AG'
    company.save
    @import.postprocess
    assert_equal(company, product.company)
  end
  def test_postprocess__search
    product = Drugs::Product.new
    product.name.de = 'Product 100% Manu'
    product.save
    company = Business::Company.new
    company.name.de = 'Manufacturer AG'
    company.save
    @import.postprocess
    assert_equal(company, product.company)
  end
  def test_postprocess__prune_packages
    pzn1 = Util::Code.new(:cid, '12345', 'DE')
    zzb1 = Util::Code.new(:zuzahlungsbefreit, 'true', 'DE')
    pac1 = Drugs::Package.new
    pac1.add_code(pzn1)
    pac1.add_code(zzb1)
    pac1.save
    pzn2 = Util::Code.new(:cid, '54321', 'DE')
    zzb2 = Util::Code.new(:zuzahlungsbefreit, 'true', 'DE')
    pac2 = Drugs::Package.new
    pac2.add_code(pzn2)
    pac2.add_code(zzb2)
    pac2.save
    @import.instance_variable_set('@confirmed_pzns',
                                 pac1.code(:cid).value => true)
    @import.postprocess
    assert_equal('true', zzb1.value)
    assert_equal(false, zzb2.value)
  end
end
  end
end
