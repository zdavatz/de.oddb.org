#!/usr/bin/env ruby
# Html::State::Drugs::Ajax::ExplainPrice -- de.oddb.org -- 07.03.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/ajax/explain_price'
require 'oddb/html/state/drugs/ajax/global'

module ODDB
  module Html
    module State
      module Drugs
        module Ajax
class ExplainPrice < Global
  VIEW = View::Drugs::Ajax::ExplainPrice
end
        end
      end
    end
  end
end
