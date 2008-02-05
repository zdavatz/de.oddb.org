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
    if((seq = @model.sequence) && (url = @session.user_input(:fi_url)))
      document = Import::PharmNet::FachInfo.new.import_rtf(WWW::Mechanize.new, url)
      seq.fachinfo.de = document
      seq.save
    end
    self
  end
end
        end
      end
    end
  end
end
