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
      def Server.remote_export_chde
        if(uri = ODDB.config.remote_databases.first)
          remote = DRb::DRbObject.new(nil, uri)
          safe_export(Export::Xls::ComparisonDeCh) { |exporter|
            remote.remote_export("chde.xls") { |path|
              File.open(path, 'w+') { |io| exporter.export(uri, io) }
            }
          }
        end
      end
      def Server.remote_export_yaml
        if(uri = ODDB.config.remote_databases.first)
          remote = DRb::DRbObject.new(nil, uri)
          safe_export(Export::Yaml::Drugs) { |exporter|
            remote.remote_export("de.oddb.yaml") { |path|
              File.open(path, 'w') { |io| exporter.export(io) }
            }
          }
        end
      end
      def Server.remote_export_fachinfo_yaml
        if(uri = ODDB.config.remote_databases.first)
          remote = DRb::DRbObject.new(nil, uri)
          safe_export(Export::Yaml::Fachinfos) { |exporter|
            remote.remote_export("fachinfos.de.oddb.yaml") { |path|
              File.open(path, 'w') { |io| exporter.export(io) }
            }
          }
        end
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
