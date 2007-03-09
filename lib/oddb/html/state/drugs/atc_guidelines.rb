#!/usr/bin/env ruby
# Html::State::Drugs::AtcGuidelines -- de.oddb.org -- 09.03.2007 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/global'
require 'oddb/html/view/drugs/atc_guidelines'

module ODDB
  module Html
    module State
      module Drugs
class AtcGuidelines < Global
  VIEW = View::Drugs::AtcGuidelines
  def direct_event
    [:ddd, :code, @model.code]
  end
end
      end
    end
  end
end
