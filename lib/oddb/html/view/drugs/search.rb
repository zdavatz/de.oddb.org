#!/usr/bin/env ruby
# Html::View::Drugs::Search -- de.oddb.org -- 12.12.2007 -- hwyss@ywesee.com

require 'oddb/html/view/search'

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
    [0,5] => :product_count,
    [0,6] => :social_bookmarks,
    [0,7] => :screencast,
  }
  CSS_MAP = {4 => "explain", 5 => "explain", 6 => "explain", 7 => "explain"}
  def product_count(model)
    link = HtmlGrid::Link.new(:products, model, @session, self)
    link.href = @lookandfeel._event_url(:products)
    [ODDB::Drugs::Package.count, '&nbsp;', link]
  end
end
      end
    end
  end
end
