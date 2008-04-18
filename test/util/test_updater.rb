#!/usr/bin/env ruby
# Util::TestUpdater -- de.oddb.org -- 05.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/util/updater'
require 'flexmock'
require 'stub/model'

module ODDB
  module Util
    class TestUpdater < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        ODDB.config.reset!
        @config = flexmock(ODDB.config)
        @var = File.expand_path('var', File.dirname(__FILE__))
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @xls_dir = File.join(@var, 'xls')
        FileUtils.rm_r(@xls_dir) if(File.exist?(@xls_dir))
        @config.should_receive(:var).and_return(@var)
        @config.should_receive(:data_dir).and_return(@data_dir)
        @updater = Updater
        @errors = []
        ODDB.logger = flexmock('logger')
        ODDB.logger.should_receive(:error).and_return { |type, block|
          msg = block.call
          puts msg
          @errors.push msg
        }
        ODDB.logger.should_ignore_missing
      end
      def test_run
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(6)
        arch = File.join(@xls_dir, 
          "liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")
        today = Date.new(2006,10)
        wirkkurz = "ftp://ftp.dimdi.de/pub/amg/wirkkurz_011006.xls"
        darform = "ftp://ftp.dimdi.de/pub/amg/darform_011006.xls"
        fbetrag = "ftp://ftp.dimdi.de/pub/amg/fb011006.xls"
        zuzahlung = "http://www.die-gesundheitsreform.de/gesetze_meilensteine/gesetze/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        index_uri = flexmock('Index-URI')
        index_uri.should_receive(:open)\
          .times(1).and_return(StringIO.new("xyzfb011006.xlsABC"))
        wirkkurz_uri = flexmock('Wirkkurz-URI')
        wirkkurz_uri.should_receive(:open)\
          .times(1).and_return { |block|
          block.call StringIO.new("wirkkurz-xls-io") 
        }
        darform_uri = flexmock('Darform-URI')
        darform_uri.should_receive(:open)\
          .times(1).and_return { |block|
          block.call StringIO.new("darform-xls-io") 
        }
        fbetrag_uri = flexmock('Festbetrag-URI')
        fbetrag_uri.should_receive(:open)\
          .times(1).and_return { |block|
          block.call StringIO.new("festbetrag-xls-io") 
        }
        zuzahlung_uri = flexmock('Zuzahlungsbefreiung-URI')
        zuzahlung_uri.should_receive(:open)\
          .times(1).and_return(StringIO.new("zuzahlung-xls-io"))
        uriparse = flexmock(URI)
        uriparse.should_receive(:parse).with(Updater::DIMDI_INDEX)\
          .times(1).and_return(index_uri)
        uriparse.should_receive(:parse).with(wirkkurz)\
          .times(1).and_return(wirkkurz_uri)
        uriparse.should_receive(:parse).with(darform)\
          .times(1).and_return(darform_uri)
        uriparse.should_receive(:parse).with(fbetrag)\
          .times(1).and_return(fbetrag_uri)
        uriparse.should_receive(:parse).with(zuzahlung)\
          .times(1).and_return(zuzahlung_uri)
        wirkkurz_import = flexmock('DimdiSubstance')
        flexmock(Import::Dimdi::Substance)\
          .should_receive(:new).with(Date.new(2006,10))\
          .and_return(wirkkurz_import)
        wirkkurz_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('wirkkurz-xls-io', io.read)
          []
        }
        darform_import = flexmock('DimdiGalenicForm')
        flexmock(Import::Dimdi::GalenicForm)\
          .should_receive(:new).and_return(darform_import)
        darform_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('darform-xls-io', io.read)
          []
        }
        fbetrag_import = flexmock('DimdiProduct')
        flexmock(Import::Dimdi::Product)\
          .should_receive(:new).and_return(fbetrag_import)
        fbetrag_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('festbetrag-xls-io', io.read)
          []
        }
        zuzahl_import = flexmock('DimdiZuzahlungsBefreiung')
        flexmock(Import::Dimdi::ZuzahlungsBefreiung)\
          .should_receive(:new).and_return(zuzahl_import)
        zuzahl_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(File, io)
          assert_equal('zuzahlung-xls-io', io.read)
          []
        }
        importer = flexmock('ProductInfos')
        stub = flexmock(Import::Csv::ProductInfos)
        stub.should_receive(:download_latest).and_return { |block|
          block.call('file-handle') }
        stub.should_receive(:new)\
          .times(1).and_return(importer)
        path = File.join(@data_dir, 'csv', 'products.csv')
        importer.should_receive(:import).with('file-handle')\
          .times(1).and_return {
          assert(true) 
          ['report']
        }
        pharmnet_import = flexmock('PharmNet')
        flexmock(Import::PharmNet::Import)\
          .should_receive(:new).and_return(pharmnet_import)
        pharmnet_import.should_receive(:_import)\
          .times(1).and_return { |agent, seqs, opts|
          assert_instance_of(WWW::Mechanize, agent)
          assert_equal([], seqs)
          []
        }
        @updater.run(today)
        assert(File.exist?(File.join(@xls_dir, 'wirkkurz_011006.xls')))
        assert(File.exist?(File.join(@xls_dir, 'darform_011006.xls')))
        assert(File.exist?(File.join(@xls_dir, 'fb011006.xls')))
        assert(File.exist?(arch))
        assert(File.exist?(File.join(@xls_dir, 
          "2006.10.01-liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")))
      end
      def test_run__errors
        arch = File.join(@xls_dir, 
          "liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")
        today = Date.new(2006,10)
        wirkkurz = "ftp://ftp.dimdi.de/pub/amg/wirkkurz_011006.xls"
        darform = "ftp://ftp.dimdi.de/pub/amg/darform_011006.xls"
        fbetrag = "ftp://ftp.dimdi.de/pub/amg/fb011006.xls"
        zuzahlung = "http://www.die-gesundheitsreform.de/gesetze_meilensteine/gesetze/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        index_uri = flexmock('Index-URI')
        index_uri.should_receive(:open)\
          .times(1).and_return(StringIO.new("xyzfb011006.xlsABC"))
        wirkkurz_uri = flexmock('Wirkkurz-URI')
        wirkkurz_uri.should_receive(:open)\
          .times(1).and_return { 
          raise "connection error 1"
        }
        darform_uri = flexmock('Darform-URI')
        darform_uri.should_receive(:open)\
          .times(1).and_return {
          raise "connection error 2"
        }
        fbetrag_uri = flexmock('Festbetrag-URI')
        fbetrag_uri.should_receive(:open)\
          .times(1).and_return { 
          raise "connection error 3"
        }
        zuzahlung_uri = flexmock('Zuzahlungsbefreiung-URI')
        zuzahlung_uri.should_receive(:open)\
          .times(1).and_return {
          raise "connection error 4"
        }
        stub = flexmock(Net::POP3)
        stub.should_receive(:start).and_return { 
          raise "connection error 5"
        }
        flexmock(Import::PharmNet::Import).new_instances\
          .should_receive(:_import)\
          .times(1).and_return { |agent, seqs, opts|
          raise "import error"
        }
        uriparse = flexmock(URI)
        uriparse.should_receive(:parse).with(Updater::DIMDI_INDEX)\
          .times(1).and_return(index_uri)
        uriparse.should_receive(:parse).with(wirkkurz)\
          .times(1).and_return(wirkkurz_uri)
        uriparse.should_receive(:parse).with(darform)\
          .times(1).and_return(darform_uri)
        uriparse.should_receive(:parse).with(fbetrag)\
          .times(1).and_return(fbetrag_uri)
        uriparse.should_receive(:parse).with(zuzahlung)\
          .times(1).and_return(zuzahlung_uri)
        flexmock(Util::Mail).should_receive(:notify_admins).times(1)
        assert_nothing_raised {
          @updater.run(today)
        }
        assert(!File.exist?(File.join(@xls_dir, 'wirkkurz_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'darform_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'fb011006.xls')))
        assert(!File.exist?(arch))
      end
      def test_run__later_errors
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(6)
        arch = File.join(@xls_dir, 
          "liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")
        today = Date.new(2006,10)
        wirkkurz = "ftp://ftp.dimdi.de/pub/amg/wirkkurz_011006.xls"
        darform = "ftp://ftp.dimdi.de/pub/amg/darform_011006.xls"
        fbetrag = "ftp://ftp.dimdi.de/pub/amg/fb011006.xls"
        zuzahlung = "http://www.die-gesundheitsreform.de/gesetze_meilensteine/gesetze/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        index_uri = flexmock('Index-URI')
        index_uri.should_receive(:open)\
          .times(1).and_return(StringIO.new("xyzfb011006.xlsABC"))
        wirkkurz_uri = flexmock('Wirkkurz-URI')
        wirkkurz_uri.should_receive(:open)\
          .times(1).and_return { |block|
          block.call StringIO.new("wirkkurz-xls-io") 
        }
        darform_uri = flexmock('Darform-URI')
        darform_uri.should_receive(:open)\
          .times(1).and_return { |block|
          block.call StringIO.new("darform-xls-io") 
        }
        fbetrag_uri = flexmock('Festbetrag-URI')
        fbetrag_uri.should_receive(:open)\
          .times(1).and_return { |block|
          block.call StringIO.new("festbetrag-xls-io") 
        }
        zuzahlung_uri = flexmock('Zuzahlungsbefreiung-URI')
        zuzahlung_uri.should_receive(:open)\
          .times(1).and_return(StringIO.new("zuzahlung-xls-io"))
        uriparse = flexmock(URI)
        uriparse.should_receive(:parse).with(Updater::DIMDI_INDEX)\
          .times(1).and_return(index_uri)
        uriparse.should_receive(:parse).with(wirkkurz)\
          .times(1).and_return(wirkkurz_uri)
        uriparse.should_receive(:parse).with(darform)\
          .times(1).and_return(darform_uri)
        uriparse.should_receive(:parse).with(fbetrag)\
          .times(1).and_return(fbetrag_uri)
        uriparse.should_receive(:parse).with(zuzahlung)\
          .times(1).and_return(zuzahlung_uri)
        wirkkurz_import = flexmock('DimdiSubstance')
        flexmock(Import::Dimdi::Substance)\
          .should_receive(:new).with(Date.new(2006,10))\
          .and_return(wirkkurz_import)
        wirkkurz_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('wirkkurz-xls-io', io.read)
          raise "import error"
        }
        darform_import = flexmock('DimdiGalenicForm')
        flexmock(Import::Dimdi::GalenicForm)\
          .should_receive(:new).and_return(darform_import)
        darform_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('darform-xls-io', io.read)
          raise "import error"
        }
        fbetrag_import = flexmock('DimdiProduct')
        flexmock(Import::Dimdi::Product)\
          .should_receive(:new).and_return(fbetrag_import)
        fbetrag_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('festbetrag-xls-io', io.read)
          raise "import error"
        }
        zuzahl_import = flexmock('DimdiZuzahlungsBefreiung')
        flexmock(Import::Dimdi::ZuzahlungsBefreiung)\
          .should_receive(:new).and_return(zuzahl_import)
        zuzahl_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(File, io)
          assert_equal('zuzahlung-xls-io', io.read)
          raise "import error"
        }
        importer = flexmock('ProductInfos')
        stub = flexmock(Import::Csv::ProductInfos)
        stub.should_receive(:download_latest).and_return { |block|
          block.call('file-handle') rescue StandardError }
        stub.should_receive(:new)\
          .times(1).and_return(importer)
        path = File.join(@data_dir, 'csv', 'products.csv')
        importer.should_receive(:import).with('file-handle')\
          .times(1).and_return { |io|
          assert_equal('file-handle', io)
          raise "import error"
        }
        flexmock(Import::PharmNet::Import).new_instances\
          .should_receive(:_import)\
          .times(1).and_return { |agent, seqs, opts|
          raise "import error"
        }
        assert_nothing_raised {
          @updater.run(today)
        }
        assert(!File.exist?(File.join(@xls_dir, 'wirkkurz_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'darform_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'fb011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 
          "2006.10.06-liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")))
      end
      def test_import_whocc_guidelines
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(1)
        importer = flexmock('Guidelines')
        flexmock(Import::Whocc::Guidelines).should_receive(:new)\
          .times(1).and_return(importer)
        importer.should_receive(:import).with(WWW::Mechanize)\
          .times(1).and_return {
          assert(true) 
          ['report']
        }
        Updater.import_whocc_guidelines
      end
      def test_import_product_infos
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(1)
        importer = flexmock('ProductInfos')
        stub = flexmock(Import::Csv::ProductInfos)
        stub.should_receive(:download_latest).and_return { |block|
          block.call('file-handle') }
        stub.should_receive(:new)\
          .times(1).and_return(importer)
        path = File.join(@data_dir, 'csv', 'products.csv')
        importer.should_receive(:import).with('file-handle')\
          .times(1).and_return {
          assert(true) 
          ['report']
        }
        Updater.import_product_infos
      end
    end
  end
end
