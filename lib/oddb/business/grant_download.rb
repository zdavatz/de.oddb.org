#!/usr/bin/env ruby
# ODDB::Business::GrantDownload -- de.oddb.org -- 18.11.2010 -- mhatakeyama@ywesee.com

require 'oddb/model'

module ODDB
  module Business
    class GrantDownload < Model
      multilingual :email
      attr_reader :grant_list
      def initialize(email)
        self.email.de = email
        @grant_list = {}
      end
      def grant_download(file, expiry_time)
        @grant_list[file] = expiry_time
      end
      def expired?(file)
        if expiry_time = @grant_list[file]
          expiry_time < Time.now
        else
          true
        end
      end
    end
  end
end
