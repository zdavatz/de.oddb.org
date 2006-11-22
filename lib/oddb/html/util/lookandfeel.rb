#!/usr/bin/env ruby
# Html::Util::Lookandfeel -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'sbsm/lookandfeel'

module ODDB
  module Html
    module Util
class Lookandfeel < SBSM::Lookandfeel
  DICTIONARIES = {
    "de"  =>  {
      :drugs        				=> 'Medikamente',
      :empty_packages       => <<-EOS,
Ihr Such-Stichwort hat zu keinem Suchergebnis geführt. Bitte
überprüfen Sie die Schreibweise und versuchen Sie es noch
einmal.
    EOS
      :home         				=> 'Home',
      :html_title   				=> 'ODDB',
      :lgpl_license 				=> 'LGPL',
      :logo         				=> 'de.oddb.org - peer reviewed open drug database',
      :oddb_version 				=> 'Commit-ID',
      :query_info    				=> 'Bitte HIER Such-Stichwort eingeben',
      :reset        				=> 'Zurücksetzen',
      :search           		=> 'Suchen',
      :th_atc               => 'ATC-Code',
      :th_company           => 'Hersteller',
      :th_doses             => 'Stärke',
      :th_festbetrag        => 'FB',
      :th_festbetragsstufe  => 'FB-Stufe',
      :th_price_public  		=> 'PP',
      :th_product   				=> 'Präparat',
      :th_size      				=> 'Packungsgrösse',
      :th_zuzahlungsbefreit => 'Zuzahlungsbefreit',
      :yes                  => 'Ja',
      :ywesee       				=> 'ywesee.com',
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
