#!/usr/bin/env ruby
# Html::State::Drugs::Init -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/global'
require 'oddb/html/view/drugs/init'

module ODDB
  module Html
    module State
      module Drugs
class Init < Global
  DIRECT_EVENT = :home_drugs
  VIEW = View::Drugs::Init
end
      end
    end
  end
end
