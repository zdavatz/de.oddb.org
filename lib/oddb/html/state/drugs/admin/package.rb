#!/usr/bin/env ruby
# Html::State::Drugs::Admin::Package -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/package'
require 'oddb/html/view/drugs/admin/package'
require 'oddb/import/pharmnet'

module ODDB
  module Html
    module State
      module Drugs
        module Admin
class Package < Drugs::Package
  VIEW = View::Drugs::Admin::Package
  def update
    fi_url = @session.user_input(:fi_url)
    pi_url = @session.user_input(:pi_url)
    if((seq = @model.sequence) && (fi_url || pi_url))
      _import_rtf(:fachinfo, seq, fi_url)
      _import_rtf(:patinfo, seq, pi_url)
      seq.save
    end
    self
  end
  def _import_rtf(key, seq, url)
    if(url && !url.empty?)
      imp = Import::PharmNet::Import.new
      document = imp.import_rtf(key, WWW::Mechanize.new, url, seq.name.de)
      seq.send(key).de = document
    end
  end
end
        end
      end
    end
  end
end
