#!/usr/bin/env ruby
# Util::Server -- de.oddb.org -- 01.09.2006 -- hwyss@ywesee.com

require 'oddb/html/util/known_user'
require 'oddb/html/util/session'
require 'oddb/html/util/validator'
require 'oddb/util/exporter'
require 'oddb/util/ipn'
require 'oddb/util/updater'
require 'oddb/export/rss'
require 'paypal'
require 'sbsm/drbserver'

module ODDB
  module Util
    class Server < SBSM::DRbServer
      ENABLE_ADMIN = true 
      SESSION = Html::Util::Session
      VALIDATOR = Html::Util::Validator
      def initialize(*args)
        super
        @rss_mutex = Mutex.new
        run_exporter if(ODDB.config.run_exporter)
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
          rescue StandardError => error
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
      def grant_download(*arg)
        email = arg[0]
        file  = arg[1]
        expiry_time = arg[2]
        if arg.length == 3      # register
          unless user = ODDB::Business::GrantDownload.find_by_email(email)
            user = ODDB::Business::GrantDownload.new(email)
          end
          user.grant_download(file, expiry_time)
          user.save
          ODDB.config.http_server + '/de/temp/grant_download/email/' + email + '/file/' + file
        elsif arg.length == 1   # search
          if user = ODDB::Business::GrantDownload.find_by_email(email)
            grant_list = user.grant_list.sort_by{|filename, expirytime| expirytime}.reverse
            str = grant_list[0..3].map{|x| x[1].strftime("%Y%m%d") + ', ' + x[0]}.join("\n")
            "grant list(total:" + grant_list.length.to_s + "): " + email + "\n" + str
          else
            'No registration for ' + email
          end
        else
          'help'
        end
      end
      def create_product name
        if prod = ODDB::Drugs::Product.find_by_name(name)
          "The product already exists. You may edit it at http://de.oddb.org/de/drugs/product/uid/#{prod.uid}"
        else
          prod = ODDB::Drugs::Product.new
          prod.name.de = name
          prod.save
          "Success! You may now edit the product at http://de.oddb.org/de/drugs/product/uid/#{prod.uid}"
        end
      end
      def generate_dictionary(language, locale)
        ODBA.storage.remove_dictionary(language)
        base = File.join(ODDB.config.data_dir,
                         "fulltext", "data", "dicts", language)
        ODBA.storage.generate_dictionary(language, locale, base)
      end
      def generate_dictionaries
        generate_dictionary('german', 'de_DE@euro')
      end
      def ipn(notification)
        Util::Ipn.process notification
        nil # don't return the invoice back across drb - it's not defined in yipn
      end
      def login(email, pass)
        session = ODDB.auth.login(email, pass, ODDB.config.auth_domain)
        Html::Util::KnownUser.new(session)
      end
      def logout(session)
        ODDB.auth.logout(session)
      rescue DRb::DRbError, RangeError, NameError
      end
      def peer_cache cache
        ODBA.peer cache
      end
      def run_at(hour, &block)
        Thread.new {
          loop {
            now = Time.now 
            run_at = Time.local(now.year, now.month, now.day, hour)
            while(now > run_at)
              run_at += 24*60*60
            end
            sleep(run_at - now)
            block.call
          }
        }
      end
      def run_exporter
        @exporter = run_at(ODDB.config.export_hour) { Exporter.run }
      end
      def run_updater
        @updater = run_at(ODDB.config.update_hour) { Updater.run }
      end
      def unpeer_cache cache
        ODBA.unpeer cache
      end
      def update_feedback_rss_feed
        async {
          begin
            @rss_mutex.synchronize {
              Export::Rss::Feedback.new.export
            }
          rescue StandardError => error
            ODDB.logger.error('rss_feed') { error.class }
            ODDB.logger.error('rss_feed') { error.message }
            ODDB.logger.error('rss_feed') { error.backtrace.pretty_inspect }
          end
        }
      end
    end
  end
end
