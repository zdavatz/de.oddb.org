#!/usr/bin/env ruby
# Html::Util::Lookandfeel -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'sbsm/lookandfeel'

module ODDB
  module Html
    module Util
class Lookandfeel < SBSM::Lookandfeel
  DICTIONARIES = {
    "de"  =>  {
      :cpr_link     => 'ywesee.com',
      :drugs        => 'Medikamente',
      :home_drugs   => 'Home',
      :html_title   => 'ODDB',
      :logo         => 'de.oddb.org - peer reviewed open drug database',
      :oddb_version => 'Commit-ID',
      :query        => 'Bitte HIER Such-Stichwort eingeben',
      :reset        => 'Zurücksetzen',
      :search       => 'Suchen',
    }
  }
  RESOURCES = {
    :logo => 'logo.gif', 
    :css  => 'oddb.css',
  }
    def base_url
      [@session.http_protocol + ':/', @session.server_name,
        @language, @session.zone].compact.join("/")
    end
end
    end
  end
end
