#!/usr/bin/env ruby
# Util::Updater -- de.oddb.org -- 02.02.2007 -- hwyss@ywesee.com

require 'date'
require 'mechanize'
require 'oddb/import/csv'
require 'oddb/import/dimdi'
require 'oddb/import/pharma24'
require 'oddb/import/pharmnet'
require 'oddb/import/whocc'
require 'oddb/util/mail'

module ODDB
  module Util
    module Updater
      DIMDI_INDEX = "http://www.dimdi.de/static/de/amg/fbag/index.htm"
      def Updater.import_dimdi_galenic_forms(date)
        file = date.strftime("darform_%d%m%y.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::GalenicForm.new(date), io)
        }
      end
      def Updater.import_dimdi_products(date)
        file = date.strftime("fb_%d%m%y.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::Product.new(date), io,
                          "Update Festbeträge")
        }
      end
      def Updater.import_dimdi_substances(date)
        file = date.strftime("wirkkurz_%d%m%y.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::Substance.new(date), io)
        }
      end
      def Updater.import_dimdi_zuzahlungsbefreiung(today)
        url = "http://www.gkv.info/gkv/index.php?id=445"
        if match = /zuzahlungsbefreiung_excel_\d+.xls/i.match(open(url).read)
          url = "http://www.gkv.info/gkv/fileadmin/user_upload/Projekte/arzneimittelzuzahlungsbefreiung/#{match}"
          Import::Dimdi.download_latest(url, today) { |io|
            reported_import(Import::Dimdi::ZuzahlungsBefreiung.new, io)
          }
        end
      end
      def Updater.import_fachinfos(term, opts = {})
        importer = Import::PharmNet::Import.new
        _reported_import(importer) {
          importer.import_missing(WWW::Mechanize.new, term, opts)
        }
      rescue StandardError => error
        ODDB.logger.error('Updater') { error.message }
      end
      def Updater.import_missing(name)
        importer = Import::Csv::ProductInfos.new
        Import::Csv::ProductInfos.open { |io|
          _reported_import(importer) {
            importer.import(io, :pattern => %r{#{name}}i, :import_known => false,
                                :import_unknown => true)
          }
        }
      end
      def Updater.import_pharmnet(opts = {})
        opts = { :replace => true,  :reload  => false, 
                 :remove  => false, :repair  => false,
                 :reparse => false, :retries => 3,
                 :retry_unit => 60 }.update opts
        importer = Import::PharmNet::Import.new
        _reported_import(importer) {
          importer._import(WWW::Mechanize.new, Drugs::Sequence.all, opts)
        }
      rescue StandardError => error
        ODDB.logger.error('Updater') { error.message }
      end
      def Updater.import_product_infos
        Import::Csv::ProductInfos.download_latest { |io|
          reported_import(Import::Csv::ProductInfos.new, io)
        }
      end
      def Updater.import_whocc_guidelines
        reported_import(Import::Whocc::Guidelines.new, 
                        WWW::Mechanize.new)
      end
      def Updater.report_fachinfos
        importer = Import::PharmNet::Import.new
        _reported_import(importer) {
          importer.report
        }
      end
      def Updater.reported_import(importer, io, subject=nil)
        _reported_import(importer, subject) { importer.import io }
      end
      def Updater._reported_import(importer, subject=nil, &block)
        lines = [
          sprintf("%s: %s#import", Time.now.strftime('%c'), importer.class)
        ]
        lines.concat block.call
      rescue StandardError => err
        lines.push(err.class.to_s, err.message, *err.backtrace)
        if importer.respond_to?(:report)
          lines.concat importer.report rescue [$!.message]
        end
        raise
      ensure
        subject = sprintf("%s: %s", 
                          Time.now.strftime('%c'), subject || importer.class)
        Mail.notify_admins(subject, lines)
      end
      def Updater.run(today = Date.today)
        if(date = Import::Dimdi.current_date(DIMDI_INDEX))
          import_dimdi_substances(date)
          import_dimdi_galenic_forms(date)
          import_dimdi_products(date)
        end
        import_dimdi_zuzahlungsbefreiung(today)
        case today.day
        when 1
          import_pharmnet
        when 15
          update_prices
        end
      end
      def Updater.update_prices(packages = Drugs::Package.all,
                                opts={:all => false})
        importer = Import::Pharma24.new
        _reported_import(importer) {
          importer.import WWW::Mechanize.new, packages
        }
      rescue StandardError => error
        ODDB.logger.error('Updater') { error.message }
      end
    end
  end
end
