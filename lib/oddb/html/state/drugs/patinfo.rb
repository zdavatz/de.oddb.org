#!/usr/bin/env ruby
# Html::State::Drugs::Patinfo -- de.oddb.org -- 30.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/patinfo'

module ODDB
  module Html
    module State
      module Drugs
class Patinfo < Global
  LIMIT = true
  VIEW = View::Drugs::Patinfo
  def direct_event
    direct_event = [:patinfo]
    if(code = @model.code(:cid, 'DE'))
      direct_event.push([:pzn, code.value])
    end
    direct_event
  end
end
      end
    end
  end
end
