#!/usr/bin/env ruby
# Util::Updater -- de.oddb.org -- 02.02.2007 -- hwyss@ywesee.com

require 'date'
require 'fileutils'
require 'open-uri'
require 'oddb/import/dimdi'
require 'oddb/config'
require 'oddb/util/mail'

module ODDB
  module Util
    module Updater
      DIMDI_INDEX = "http://www.dimdi.de/static/de/amg/fbag/index.htm"
      DIMDI_PATH = "ftp://ftp.dimdi.de/pub/amg/"
      def Updater.dimdi_current_date(url)
        if(match = /fb(\d\d)(\d\d)(\d\d)\.xls/.match(open(url).read))
          Date.new(2000 + match[3].to_i, match[2].to_i, match[1].to_i)
        end
      end
      def Updater.download_from_dimdi(file, &block)
        url = File.join(DIMDI_PATH, file)
        xls_dir = File.join(ODDB.config.data_dir, 'xls')
        FileUtils.mkdir_p(xls_dir)
        dest = File.join(xls_dir, file)
        unless(File.exist?(dest))
          open(url) { |remote| 
            block.call(remote)
            remote.rewind
            open(dest, 'w') { |local|
              local << remote.read
            }
          }
        end
      rescue Exception => err
        #
      end
      def Updater.download_latest(url, today, &block)
        file = File.basename(url)
        xls_dir = File.join(ODDB.config.data_dir, 'xls')
        FileUtils.mkdir_p(xls_dir)
        dest = File.join(xls_dir, file)
        archive = File.join(ODDB.config.data_dir, 'xls', 
                    sprintf("%s-%s", today.strftime("%Y.%m.%d"), file))
        content = open(url).read
        if(!File.exist?(dest) || content.size != File.size(dest))
          open(archive, 'w') { |local|
            local << content
          }
          open(archive, 'r', &block)
          open(dest, 'w') { |local|
            local << content
          }
        end
      rescue Exception
        #
      end
      def Updater.import_dimdi_galenic_forms(date)
        file = date.strftime("darform_%d%m%y.xls")
        download_from_dimdi(file) { |io|
          reported_import(Import::DimdiGalenicForm.new(date), io)
        }
      end
      def Updater.import_dimdi_products(date)
        file = date.strftime("fb%d%m%y.xls")
        download_from_dimdi(file) { |io|
          reported_import(Import::DimdiProduct.new(date), io)
        }
      end
      def Updater.import_dimdi_substances(date)
        file = date.strftime("wirkkurz_%d%m%y.xls")
        download_from_dimdi(file) { |io|
          reported_import(Import::DimdiSubstance.new(date), io)
        }
      end
      def Updater.import_dimdi_zuzahlungsbefreiung(today)
        url = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel_suchfunktion.xls"
        download_latest(url, today) { |io|
          reported_import(Import::DimdiZuzahlungsBefreiung.new, io)
        }
      end
      def Updater.reported_import(importer, io)
        lines = [
          sprintf("%s: %s#import", 
                  Time.now.strftime('%c'), importer.class)
        ]
        lines.concat importer.import(io)
      rescue Exception => err
        lines.push(err.class, err.message, *err.backtrace)
        raise
      ensure
        subject = sprintf("%s: %s", 
                          Time.now.strftime('%c'), importer.class)
        Mail.notify_admins(subject, lines)
      end
      def Updater.run(today = Date.today)
        if(date = dimdi_current_date(DIMDI_INDEX))
          import_dimdi_substances(date)
          import_dimdi_galenic_forms(date)
          import_dimdi_products(date)
        end
        import_dimdi_zuzahlungsbefreiung(today)
      end
    end
  end
end
