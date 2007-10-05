#!/usr/bin/env ruby
# Util::Exporter -- de.oddb.org -- 02.10.2007 -- hwyss@ywesee.com

require 'date'
require 'drb'
require 'oddb/config'
require 'oddb/export/xls'
require 'oddb/util/mail'

module ODDB
  module Util
    module Exporter
      def Exporter.remote_export_chde
        if(uri = ODDB.config.remote_databases.first)
          remote = DRb::DRbObject.new(nil, uri)
          safe_export(Export::Xls::ComparisonDeCh) { |exporter|
            remote.remote_export("chde.xls") { |io|
              exporter.export(uri, io)
            }
          }
        end
      end
      def Exporter.run(today = Date.today)
        on_monthday(1, today) {
          remote_export_chde
        }
      end
      def Exporter.on_monthday(day, today = Date.today, &block)
        if(today.day == day)
          block.call
        end
      end
      def Exporter.safe_export(exporter, &block)
        block.call(exporter.new)
      rescue StandardError => err
        subject = sprintf("%s: %s", 
                          Time.now.strftime('%c'), exporter)
        lines = [
          sprintf("%s: %s#export", 
                  Time.now.strftime('%c'), exporter)
        ]
        lines.push(err.class, err.message, *err.backtrace)
        Mail.notify_admins(subject, lines)
      end
    end
  end
end
