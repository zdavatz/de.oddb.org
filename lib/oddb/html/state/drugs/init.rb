#!/usr/bin/env ruby
# Html::State::Drugs::Init -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/init'

module ODDB
  module Html
    module State
      module Drugs
class Init < Drugs::Global
  DIRECT_EVENT = :home
  VIEW = View::Drugs::Init
end
      end
    end
  end
end
