#!/usr/bin/env ruby
# ODDB::Business::GrantDownload -- de.oddb.org -- 18.11.2010 -- mhatakeyama@ywesee.com

require 'oddb/business/grant_download'
require 'oddb/persistence/odba/model'

module ODDB
  module Business
    class GrantDownload < Model
      odba_index :email
      serialize :grant_list
    end
  end
end
