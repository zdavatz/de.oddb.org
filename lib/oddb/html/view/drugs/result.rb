#!/usr/bin/env ruby
# Html::View::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/div'
require 'htmlgrid/span'
require 'oddb/html/view/google'
require 'oddb/html/view/list'
require 'oddb/html/view/search'
require 'oddb/html/view/drugs/legend'
require 'oddb/html/view/drugs/package'
require 'oddb/html/view/drugs/products'
require 'oddb/html/view/drugs/template'

module ODDB
  module Html
    module View
      module Drugs
class Packages < View::List
  include PackageMethods
  include ProductMethods
  include View::Google
  EMPTY_LIST_KEY = :empty_packages
  def init
    @components = @lookandfeel.result_components
    @components.each { |key, val|
      css_map.store(key, val.to_s)
    }
    @css_head_map = @css_map
    super
  end
  def compose_empty_list(offset)
    if(key = @model.error)
      fill_row(offset, key, 'warn')
    else
      super(offset, 'info')
    end
  end
  def price_difference(model)
    if((pf = model.price(:festbetrag)) && (pp = model.price(:public)))
      sprintf("%+1.2f", adjust_price(pp - pf))
    end
  end
end
class ResultComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => :title_found, 
    [0,1] => "explain_compare", 
    [0,2] => InlineSearch, 
    [0,3] => Packages, 
    [0,4] => Legend,
  }
  CSS_ID_MAP = ['result-found', 'explain-compare', 'result-search', 
                'result-list', 'legend' ]
  CSS_MAP = { 1 => 'before-searchbar', 3 => 'result' }
  def title_found(model)
    @lookandfeel.lookup(:title_found, @model.query, @model.size)
  end
end
class Result < Template
  CONTENT = ResultComposite
end
      end
    end
  end
end
