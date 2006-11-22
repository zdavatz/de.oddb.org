#!/usr/bin/env ruby
# Html::View::Drugs::Init -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/template'
require 'oddb/html/view/search'

module ODDB
  module Html
    module View
      module Drugs
class Init < Template
  CONTENT = Search
  CSS_ID_MAP = ['head', 'home-search', 'foot']
end
      end
    end
  end
end
