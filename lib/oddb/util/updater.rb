#!/usr/bin/env ruby
# Util::Updater -- de.oddb.org -- 02.02.2007 -- hwyss@ywesee.com

require 'date'
require 'mechanize'
require 'oddb/import/csv'
require 'oddb/import/dimdi'
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
        file = date.strftime("fb%d%m%y.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::Product.new(date), io)
        }
      end
      def Updater.import_dimdi_substances(date)
        file = date.strftime("wirkkurz_%d%m%y.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::Substance.new(date), io)
        }
      end
      def Updater.import_dimdi_zuzahlungsbefreiung(today)
        url = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        Import::Dimdi.download_latest(url, today) { |io|
          reported_import(Import::Dimdi::ZuzahlungsBefreiung.new, io)
        }
      end
      def Updater.import_product_infos(path=nil)
        path ||= File.join(ODDB.config.data_dir, 'csv', 'products.csv')
        File.open(path) { |io|
          reported_import(Import::Csv::ProductInfos.new, io)
        }
      end
      def Updater.import_whocc_guidelines
        reported_import(Import::Whocc::Guidelines.new, 
                        WWW::Mechanize.new)
      end
      def Updater.reported_import(importer, io)
        lines = [
          sprintf("%s: %s#import", 
                  Time.now.strftime('%c'), importer.class)
        ]
        lines.concat importer.import(io)
      rescue StandardError => err
        lines.push(err.class, err.message, *err.backtrace)
        raise
      ensure
        subject = sprintf("%s: %s", 
                          Time.now.strftime('%c'), importer.class)
        Mail.notify_admins(subject, lines)
      end
      def Updater.run(today = Date.today)
        if(date = Import::Dimdi.current_date(DIMDI_INDEX))
          import_dimdi_substances(date)
          import_dimdi_galenic_forms(date)
          import_dimdi_products(date)
        end
        import_dimdi_zuzahlungsbefreiung(today)
      end
    end
  end
end
