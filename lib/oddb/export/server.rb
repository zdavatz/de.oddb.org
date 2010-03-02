#!/usr/bin/env ruby
# Export::Server -- de.oddb.org -- 10.10.2007 -- hwyss@ywesee.com

require 'date'
require 'drb'
require 'oddb/config'
require 'oddb/export/xls'
require 'oddb/export/yaml'
require 'oddb/util/mail'

module ODDB
  module Export
    module Server
      def Server.remote_export exporter_class, file_name, *args
        if (uri = ODDB.config.remote_export_server) \
          && (dir = ODDB.config.remote_export_dir)
          remote = DRb::DRbObject.new(nil, uri)
          safe_export(exporter_class) do |exporter|
            remote.remote_safe_export(dir, file_name) do |path|
              File.open(path, 'w') do |io|
                args.push io
                exporter.export *args
              end
            end
          end
        end
      end
      def Server.remote_export_chde
        if uri = ODDB.config.remote_databases.first
          remote_export Export::Xls::ComparisonDeCh, 'chde.xls', uri
        end
      end
      def Server.remote_export_yaml
        remote_export Export::Yaml::Drugs, 'de.oddb.yaml'
      end
      def Server.remote_export_fachinfo_yaml
        remote_export Export::Yaml::Fachinfos, 'fachinfos.de.oddb.yaml'
      end
      def Server.run(today = Date.today)
        on_monthday(1, today) {
          remote_export_chde
        }
        on_monthday(2, today) do
          remote_export_fachinfo_yaml
        end
      end
      def Server.on_monthday(day, today = Date.today, &block)
        if(today.day == day)
          block.call
        end
      end
      def Server.safe_export(exporter, &block)
        block.call(exporter.new)
      rescue StandardError => err
        subject = sprintf("%s: %s", 
                          Time.now.strftime('%c'), exporter)
        lines = [
          sprintf("%s: %s#export", 
                  Time.now.strftime('%c'), exporter)
        ]
        lines.push(err.class, err.message, *err.backtrace)
        Util::Mail.notify_admins(subject, lines)
      end
    end
  end
end
