#!/usr/bin/env ruby
# Util::Updater -- de.oddb.org -- 02.02.2007 -- hwyss@ywesee.com

require 'date'
require 'mechanize'
require 'oddb/import/dimdi'
require 'oddb/import/gkv'
require 'oddb/import/pharma24'
require 'oddb/import/pharmnet'
require 'oddb/import/whocc'
require 'oddb/util/mail'

module ODDB
  module Util
    module Updater
      DIMDI_INDEX = "http://www.dimdi.de/static/de/amg/fbag/index.htm"
      def Updater.import_dimdi
        if(date = Import::Dimdi.current_date(DIMDI_INDEX))
          import_dimdi_substances(date)
          import_dimdi_galenic_forms(date)
          import_dimdi_products(date)
        end
      end
      def Updater.import_dimdi_galenic_forms(date)
        file = date.strftime("darreichungsformen-%Y%m.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::GalenicForm.new(date), io,
                          :filetype => 'XLS')
        }
      end
      def Updater.import_dimdi_products(date)
        file = date.strftime("festbetraege-%Y%m.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::Product.new(date), io,
                         :subject => "Update Festbeträge",
                         :filetype => 'XLS')
        }
      end
      def Updater.import_dimdi_substances(date)
        file = date.strftime("wirkstoffkuerzel-%Y%m.xls")
        Import::Dimdi.download(file) { |io|
          reported_import(Import::Dimdi::Substance.new(date), io,
                          :filetype => 'XLS')
        }
      end
      def Updater.import_fachinfos(term, opts = {})
        importer = Import::PharmNet::Importer.new
        _reported_import(importer, :filetype => 'HTML') {
          importer.import_missing(Mechanize.new, term, opts)
        }
      rescue StandardError => error
        ODDB.logger.error('Updater') { error.message }
      end
      def Updater.import_gkv(opts = {})
        importer = Import::Gkv.new
        if url = opts[:pdf] || importer.latest_url(Mechanize.new, opts)
          importer.download_latest url, opts do |fh|
            reported_import(importer, fh,
                            :subject => 'Zubef', :filetype => 'PDF')
          end
        else
          # This is temporary solution.
          # This should be composed in reporting email or logging process.
          host = 'https://www.gkv-spitzenverband.de'
          url = '/Befreiungsliste_Arzneimittel_Versicherte.gkvnet'

          print "WARNING: Updater.import_gkv did nothing. It looks failing in grabbing PDF link.\n" 
          print "Check HTML source code at " + host + url + "\n"

          print "Probably you have to modify Gkv#latest_url method, in particular, "
          print "this part: link = (page/'a[@class=pdf]')\n"
          print "20100910 masa\n"

          return nil
        end
      end
      def Updater.import_missing(name)
        name.split('|').each do |term|
          Updater.import_fachinfos term, :info_unrestricted => true
        end
      end
      def Updater.import_pharmnet(opts = {})
        opts = { :replace => true,  :reload  => false, 
                 :remove  => false, :repair  => false,
                 :reparse => false, :retries => 3,
                 :retry_unit => 60 }.update opts
        importer = Import::PharmNet::Importer.new
        _reported_import(importer, {:filetype => 'HTML'}, {:skip_totals => true}) {
          importer._import(Mechanize.new, Drugs::Sequence.all, opts)
        }
      rescue StandardError => error
        ODDB.logger.error('Updater') { error.message }
      end
      def Updater.import_product_infos
        Import::Csv::ProductInfos.download_latest { |io|
          reported_import(Import::Csv::ProductInfos.new, io, :filetype => 'CSV')
        }
      end
      def Updater.import_whocc_guidelines
        reported_import(Import::Whocc::Guidelines.new, 
                        Mechanize.new, :filetype => 'HTML')
      end
      def Updater.report_fachinfos
        importer = Import::PharmNet::Importer.new
        _reported_import(importer) {
          importer.report
        }
      end
      def Updater.reported_import(importer, io, subject=nil)
        _reported_import(importer, subject) { importer.import io }
      end
      def Updater._reported_import(importer, args={}, error_args={}, &block)
        lines = [
          sprintf("%s: %s %s#import", Time.now.strftime('%c'),
                  ODDB.config.server_name, importer.class)
        ]
        lines.concat block.call(importer)
      rescue Exception => err
        lines.push(err.class.to_s, err.message, *err.backtrace)
        if importer.respond_to?(:report)
          report = if importer.method(:report).arity == 0
                     importer.report
                   else
                     importer.report(error_args)
                   end rescue [$!.message]
          lines.concat report
        end
      ensure
        ft = args[:filetype]
        fmt = ft ? "%s: %s %s (%s)" : "%s: %s %s"
        subject = sprintf(fmt, Time.now.strftime('%c'), ODDB.config.server_name,
                          args[:subject] || importer.class, ft)
        Mail.notify_admins(subject, lines)
      end
      def Updater.run(today = Date.today)
        run_logged_job 'import_dimdi'
        run_logged_job 'import_gkv'
        case today.day
        when 1
          run_logged_job 'import_pharmnet'
          run_logged_job 'import_whocc'
        when 15
          run_logged_job 'import_pharma24'
        end
      end
      def Updater.run_logged_job job
        dir = ODDB.config.oddb_dir
        cmd = File.join dir, 'jobs', job
        log = File.join dir, 'log', job
        IO.popen "#{cmd} log_file=#{log}" do |io|
          # wait for importer to exit
        end
      end
      def Updater.update_prices(packages = Drugs::Package.all,
                                opts={:all => false})
        importer = Import::Pharma24.new
        _reported_import(importer) {
          importer.import Mechanize.new, packages
        }
      rescue StandardError => error
        ODDB.logger.error('Updater') { error.message }
      end
    end
  end
end
