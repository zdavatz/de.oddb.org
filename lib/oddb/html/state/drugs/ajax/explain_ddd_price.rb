#!/usr/bin/env ruby
# Html::State::Drugs::Ajax::ExplainDddPrice -- de.oddb.org -- 07.03.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/ajax/explain_ddd_price'
require 'oddb/html/state/drugs/ajax/global'

module ODDB
  module Html
    module State
      module Drugs
        module Ajax
class ExplainDddPrice < Global
  VIEW = View::Drugs::Ajax::ExplainDddPrice
end
        end
      end
    end
  end
end
