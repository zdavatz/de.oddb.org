#!/usr/bin/env ruby
# Html::State::Drugs::Fachinfo -- de.oddb.org -- 30.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/fachinfo'

module ODDB
  module Html
    module State
      module Drugs
class Fachinfo < Global
  LIMIT = true
  VIEW = View::Drugs::Fachinfo
  def direct_event
    [:fachinfo, [:uid, @model.uid]]
  end
end
      end
    end
  end
end
