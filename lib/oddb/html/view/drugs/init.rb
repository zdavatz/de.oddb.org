#!/usr/bin/env ruby
# Html::View::Drugs::Init -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'htmlgrid/divform'
require 'htmlgrid/reset'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/searchbar'

module ODDB
  module Html
    module View
      module Drugs
class CenteredSearch < HtmlGrid::DivForm
  EVENT = :search
  COMPONENTS = {
    [0,0] => :query,
    [0,1] => :submit,
    [1,1] => :reset,
  }
  SYMBOL_MAP = {
    :query => SearchBar,
    :reset => HtmlGrid::Reset,
  }
end
class Init < Template
  CONTENT = CenteredSearch
  CSS_ID_MAP = {
    1 => 'home-search'
  }
end
      end
    end
  end
end
