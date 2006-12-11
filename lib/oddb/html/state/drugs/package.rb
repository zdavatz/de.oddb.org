#!/usr/bin/env ruby
# Html::State::Drugs::Package -- de.oddb.org -- 11.12.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module State
      module Drugs
class Package < Global
  VIEW = View::Drugs::Package
end
      end
    end
  end
end
