#!/usr/bin/env ruby
# Html::State::Drugs::AtcBrowser -- de.oddb.org -- 13.12.2007 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/atc_browser'

module ODDB
  module Html
    module State
      module Drugs
class AtcBrowser < Drugs::Global
  DIRECT_EVENT = :atc_browser
  VIEW = View::Drugs::AtcBrowser
  def init
    @model = ODDB::Drugs::Atc.search_by_level_and_code(1, '')
    if(code = @session.user_input(:code))
      parent = ODDB::Drugs::Atc.find_by_code(code)
      level = parent.level.next
      children = ODDB::Drugs::Atc.search_by_level_and_code(level, parent.code)
      while(level < 5 && children.size == 1)
        child = children.first
        level = level.next
        children = ODDB::Drugs::Atc.search_by_level_and_code(level, child.code)
        @model.concat children
      end 
      parent.level.next.downto(2) { |level|
        @model.concat ODDB::Drugs::Atc.search_by_level_and_code(level, 
                                                                parent.code)
        parent = parent.parent
      }
    end
    @model.sort!
  end
end
      end
    end
  end
end
