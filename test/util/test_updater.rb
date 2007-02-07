#!/usr/bin/env ruby
# Util::TestUpdater -- de.oddb.org -- 05.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/util/updater'
require 'flexmock'

module ODDB
  module Util
    class TestUpdater < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @config = flexstub(ODDB.config)
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @xls_dir = File.join(@data_dir, 'xls')
        FileUtils.rm_r(@xls_dir) if(File.exist?(@xls_dir))
        @config.should_receive(:data_dir).and_return(@data_dir)
        @updater = Updater
      end
      def test_run
        flexstub(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(4)
        arch = File.join(@xls_dir, 
          "liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")
        today = Date.new(2006,10)
        wirkkurz = "ftp://ftp.dimdi.de/pub/amg/wirkkurz_011006.xls"
        darform = "ftp://ftp.dimdi.de/pub/amg/darform_011006.xls"
        fbetrag = "ftp://ftp.dimdi.de/pub/amg/fb011006.xls"
        zuzahlung = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
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
        uriparse = flexstub(URI)
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
        flexstub(Import::DimdiSubstance)\
          .should_receive(:new).with(Date.new(2006,10))\
          .and_return(wirkkurz_import)
        wirkkurz_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('wirkkurz-xls-io', io.read)
          []
        }
        darform_import = flexmock('DimdiGalenicForm')
        flexstub(Import::DimdiGalenicForm)\
          .should_receive(:new).and_return(darform_import)
        darform_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('darform-xls-io', io.read)
          []
        }
        fbetrag_import = flexmock('DimdiProduct')
        flexstub(Import::DimdiProduct)\
          .should_receive(:new).and_return(fbetrag_import)
        fbetrag_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('festbetrag-xls-io', io.read)
          []
        }
        zuzahl_import = flexmock('DimdiZuzahlungsBefreiung')
        flexstub(Import::DimdiZuzahlungsBefreiung)\
          .should_receive(:new).and_return(zuzahl_import)
        zuzahl_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(File, io)
          assert_equal('zuzahlung-xls-io', io.read)
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
        zuzahlung = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
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
        uriparse = flexstub(URI)
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
        assert_nothing_raised {
          @updater.run(today)
        }
        assert(!File.exist?(File.join(@xls_dir, 'wirkkurz_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'darform_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'fb011006.xls')))
        assert(!File.exist?(arch))
      end
      def test_run__later_errors
        flexstub(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(4)
        arch = File.join(@xls_dir, 
          "liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")
        today = Date.new(2006,10)
        wirkkurz = "ftp://ftp.dimdi.de/pub/amg/wirkkurz_011006.xls"
        darform = "ftp://ftp.dimdi.de/pub/amg/darform_011006.xls"
        fbetrag = "ftp://ftp.dimdi.de/pub/amg/fb011006.xls"
        zuzahlung = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
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
        uriparse = flexstub(URI)
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
        flexstub(Import::DimdiSubstance)\
          .should_receive(:new).with(Date.new(2006,10))\
          .and_return(wirkkurz_import)
        wirkkurz_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('wirkkurz-xls-io', io.read)
          raise "import error"
        }
        darform_import = flexmock('DimdiGalenicForm')
        flexstub(Import::DimdiGalenicForm)\
          .should_receive(:new).and_return(darform_import)
        darform_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('darform-xls-io', io.read)
          raise "import error"
        }
        fbetrag_import = flexmock('DimdiProduct')
        flexstub(Import::DimdiProduct)\
          .should_receive(:new).and_return(fbetrag_import)
        fbetrag_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(StringIO, io)
          assert_equal('festbetrag-xls-io', io.read)
          raise "import error"
        }
        zuzahl_import = flexmock('DimdiZuzahlungsBefreiung')
        flexstub(Import::DimdiZuzahlungsBefreiung)\
          .should_receive(:new).and_return(zuzahl_import)
        zuzahl_import.should_receive(:import)\
          .times(1).and_return { |io|
          assert_instance_of(File, io)
          assert_equal('zuzahlung-xls-io', io.read)
          raise "import error"
        }
        @updater.run(today)
        assert(!File.exist?(File.join(@xls_dir, 'wirkkurz_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'darform_011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 'fb011006.xls')))
        assert(!File.exist?(File.join(@xls_dir, 
          "2006.10.06-liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls")))
      end
      def test_download_latest__only_once
        today = Date.new(2006,10)
        file = "liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        path = File.join(@xls_dir, file)
        arch = File.join(@xls_dir, sprintf("2006.10.01-%s", file))
        zuzahlung = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        zuzahlung_uri = flexmock('Zuzahlungsbefreiung-URI')
        zuzahlung_uri.should_receive(:open)\
          .times(2).and_return { 
          StringIO.new("download_latest-io-read")
        }
        uriparse = flexstub(URI)
        uriparse.should_receive(:parse).with(zuzahlung)\
          .times(2).and_return(zuzahlung_uri)
        @updater.download_latest(zuzahlung, today) { |fh|
          assert_equal('download_latest-io-read', fh.read)
        }
        assert(File.exist?(path))
        assert(File.exist?(arch))
        @updater.download_latest(zuzahlung, today) { |fh|
          flunk("should not be called again")
        }
      end
      def test_dimdi_current_date
        path = File.join(@data_dir, 'html', 'dimdi_index.html')
        assert_equal(Date.new(2007), @updater.dimdi_current_date(path))
      end
    end
  end
end
