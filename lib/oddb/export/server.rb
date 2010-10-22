#!/usr/bin/env ruby
# Export::Server -- de.oddb.org -- 10.10.2007 -- hwyss@ywesee.com

require 'date'
require 'drb'
require 'oddb/config'
require File.join('oddb', 'persistence', ODDB.config.persistence, 'export')
require 'oddb/export/csv'
require 'oddb/export/xls'
require 'oddb/export/yaml'
require 'oddb/util/mail'
require 'zip/zip'

module ODDB
  module Export
    module Server
      def Server.export_csv
        pacs = Drugs::Package.all
        components = [ :pzn, :product, :active_agents, :size, :price_exfactory,
                       :price_public, :price_festbetrag, :ddd_prices, :company ]
        safe_export Csv::Packages, 'de.oddb.csv', pacs, components, :de
      end
      def Server.export_chde_xls
        if uri = ODDB.config.remote_databases.first
          safe_export Export::Xls::ComparisonDeCh, 'chde.xls', uri
        end
      end
      def Server.export_yaml
        safe_export Export::Yaml::Drugs, 'de.oddb.yaml'
      end
      def Server.export_fachinfo_yaml
        safe_export Export::Yaml::Fachinfos, "fachinfos.de.oddb.yaml"
      end
      def Server.export_patinfo_yaml
        safe_export Export::Yaml::Patinfos, "patinfos.de.oddb.yaml"
      end
      def Server.run(today = Date.today)
        on_monthday(1, today) {
          export_chde_xls
        }
        on_monthday(2, today) do
          export_info_yaml :fachinfo
          export_info_yaml :patinfo
        end
      end
      def Server.on_monthday(day, today = Date.today, &block)
        if(today.day == day)
          block.call
        end
      end
      def Server.safe_export(exporter_class, name, *args, &block)
        dir = ODDB.config.export_dir or raise "Please configure 'export_dir'"
        FileUtils.mkdir_p(dir)
        Tempfile.open(name, dir) { |fh|
          exporter = exporter_class.new
          args.push fh
          exporter.export *args
          fh.close
          newpath = File.join(dir, name)
          FileUtils.mv(fh.path, newpath)
          FileUtils.chmod(0644, newpath)
          compress(dir, name)
          # This is a temporary solution for a NoMethodError bug
          # See the bug http://dev.ywesee.com/wiki.php/Masa/20101020-debug-importChdeXls#DebugChde
          if(exporter_class ==  Export::Xls::ComparisonDeCh)
            unless(exporter.error_data.empty?)
              message = "\nThe chde.xls file was generated successfully.\n\n"
              message += "The following data was not able to be compared due to a NoMethodError:\n"
              backtrace_info = "The original backtrace information:\n" + exporter.backtrace_info.join("\n").to_s + "\n"
              raise NoMethodError, message + exporter.error_data.join("\n").to_s + "\n\n" + backtrace_info
            end
          end
        }
        name
      rescue StandardError => err
        subject = sprintf("%s: %s", 
                          Time.now.strftime('%c'), exporter_class)
        lines = [
          sprintf("%s: %s#export", 
                  Time.now.strftime('%c'), exporter_class)
        ]
        lines.push(err.class, err.message, *err.backtrace)
        Util::Mail.notify_admins(subject, lines)
      end
      def Server.compress(dir, name)
        FileUtils.mkdir_p(dir)
        Dir.chdir(dir)
        tmp_name = name + '.tmp'
        gz_name = tmp_name + '.gz'
        zip_name = tmp_name + '.zip'
        gzwriter = 	Zlib::GzipWriter.open(gz_name)
        zipwriter = Zip::ZipOutputStream.open(zip_name)
        zipwriter.put_next_entry(name)
        File.open(name, "r") { |fh|
          fh.each { |line|
            gzwriter << line
            zipwriter.puts(line)
          }
        }
        gzwriter.close if(gzwriter)
        zipwriter.close if(zipwriter)
        FileUtils.mv(gz_name, name + '.gz')
        FileUtils.mv(zip_name, name + '.zip')
        name
      end
    end
  end
end
