#!/usr/bin/env ruby
# Util::Server -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/html/util/session'
require 'oddb/html/util/validator'
require 'sbsm/drbserver'

module ODDB
  module Util
    class Server < SBSM::DRbServer
      ENABLE_ADMIN = true 
      SESSION = Html::Util::Session
      VALIDATOR = Html::Util::Validator
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
    end
  end
end
