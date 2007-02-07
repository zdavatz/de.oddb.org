#!/usr/bin/env ruby
# Util::Server -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/html/util/session'
require 'oddb/html/util/validator'
require 'oddb/util/updater'
require 'sbsm/drbserver'

module ODDB
  module Util
    class Server < SBSM::DRbServer
      ENABLE_ADMIN = true 
      SESSION = Html::Util::Session
      VALIDATOR = Html::Util::Validator
      def initialize(*args)
        super
        run_updater if(ODDB.config.run_updater)
      end
      def _admin(src, result, priority=0)
        raise "admin interface disabled" unless(self::class::ENABLE_ADMIN)
        t = Thread.new {
          Thread.current.abort_on_exception = false
          begin
            response = instance_eval(src)
            str = response.to_s
            result << if(str.length > 200)
              response.class
            else
              str
            end.to_s
          rescue Exception => error
            result << error.message
            require 'pp'
            ODDB.logger.error('admin') { error.class }
            ODDB.logger.error('admin') { error.message }
            ODDB.logger.error('admin') { error.backtrace.pretty_inspect }
            error
          end
        }
        t[:source] = src
        t.priority = priority
        @admin_threads.add(t)
        t
      end
      def run_updater
        @updater = Thread.new {
          loop {
            hour = ODDB.config.update_hour
            now = Time.now 
            run_at = Time.local(now.year, now.month, now.day, hour)
            while(now > run_at)
              run_at += 24*60*60
            end
            sleep(run_at - now)
            Updater.run
          }
        }
      end
    end
  end
end
