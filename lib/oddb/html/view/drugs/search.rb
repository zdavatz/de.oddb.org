#!/usr/bin/env ruby
# Html::View::Drugs::Search -- de.oddb.org -- 12.12.2007 -- hwyss@ywesee.com

require 'oddb/html/view/search'
require 'oddb/html/view/navigation'

module ODDB
  module Html
    module View
      module Drugs
class Search < View::Search
  COMPONENTS = {
    [0,0] => 'dstype',
    [0,1] => :dstype,
    [0,2] => :query,
    [0,3] => :submit,
    [1,3] => :reset,
    [0,4] => "explain_search",
    [0,5] => :package_count,
    [2,5] => Navigation,
    [0,6] => :social_bookmarks,
    [0,7] => :screencast,
  }
  CSS_MAP = { 4 => "explain", 5 => "explain links", 
              6 => "explain", 7 => "explain" }
  def package_count(model)
    ODDB::Drugs::Package.count
  end
end
      end
    end
  end
end
