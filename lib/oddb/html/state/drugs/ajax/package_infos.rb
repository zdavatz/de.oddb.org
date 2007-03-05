#!/usr/bin/env ruby
# Html::State::Drugs::Ajax::PackageInfos -- de.oddb.org -- 05.03.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/result'

module ODDB
  module Html
    module State
      module Drugs
        module Ajax
class PackageInfos < Global
  VOLATILE = true
  VIEW = View::Drugs::PackageInfos
end
        end
      end
    end
  end
end
