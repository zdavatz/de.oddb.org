#!/usr/bin/env ruby
# Drugs::Ajax::RemoteInfos -- de.oddb.org -- 06.03.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/result'

module ODDB
  module Html
    module State
      module Drugs
        module Ajax
class RemoteInfos < Global
  VOLATILE = true
  VIEW = View::Drugs::RemoteInfos
end
        end
      end
    end
  end
end
