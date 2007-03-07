#!/usr/bin/env ruby
# Drugs::Ajax::RemoteInfos -- de.oddb.org -- 06.03.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/ajax/remote_infos'
require 'oddb/html/state/drugs/ajax/global'

module ODDB
  module Html
    module State
      module Drugs
        module Ajax
class RemoteInfos < Global
  VIEW = View::Drugs::Ajax::RemoteInfos
end
        end
      end
    end
  end
end
