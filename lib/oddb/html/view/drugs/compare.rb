#!/usr/bin/env ruby
# Html::View::Drugs::Compare -- de.oddb.org -- 14.02.2007 -- hwyss@ywesee.com

require 'oddb/html/view/google'
require 'oddb/html/view/list'
require 'oddb/html/view/search'
require 'oddb/html/view/snapback'
require 'oddb/html/view/drugs/legend'
require 'oddb/html/view/drugs/package'
require 'oddb/html/view/drugs/products'
require 'oddb/html/view/drugs/template'

module ODDB
  module Html
    module View
      module Drugs
class CompareList < View::List
  include PackageMethods
  include ProductMethods
  include View::Google
  COMPONENTS = {
    [0,0] => :product,
    [1,0] => :company,
    [2,0] => :active_agents,
    [3,0] => :size, 
    [4,0] => :price_public,
    [5,0] => :ddd_prices,
    [6,0] => :difference,
    [7,0] => :google,
  }
  css_map = {}
  COMPONENTS.each { |key, val|
    css_map.store(key, val.to_s)
  }
  CSS_MAP = css_map
  CSS_HEAD_MAP = css_map
  EMPTY_LIST_KEY = :empty_comparison
  def compose_header(offset=[0,0])
    offset = super
    mdl = @model.origin
    _compose(mdl, offset)
    css = ['origin', row_css(mdl, nil)].compact.join(' ')
    @grid.set_row_attributes({'class' => css}, offset.at(1))
    resolve_offset(offset, self::class::OFFSET_STEP)
  end
  def difference(model)
    if(model.respond_to?(:difference) && (difference = model.difference))
      span = HtmlGrid::Span.new(model, @session, self)
      if(difference < 0)
        span.css_class = 'less'
      elsif(difference > 0)
        span.css_class = 'more'
      else
        span.css_class = 'same'
      end
      span.value = sprintf("%+2.1f%%", difference)
      span
    end
  end
  def query_key
    @model.origin.is_a?(Remote::Drugs::Package) ? :uid : :pzn
  end
end
class CompareComposite < HtmlGrid::DivComposite
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback,
    [0,1] => "explain_compare", 
    [0,2] => InlineSearch, 
    [0,3] => CompareList,
    [0,4] => Legend,
  }
  CSS_ID_MAP = [ 'snapback', 'explain-compare', 'result-search',
                 'compare-list', 'legend' ]
  CSS_MAP = { 1 => 'before-searchbar', 3 => 'result' }
  def comparison_for(model)
    @lookandfeel.lookup(:comparison_for, 
                        model.origin.name.send(@session.language))
  end
  def snapback(model)
    [ super, @lookandfeel.lookup(:breadcrumb_divider), 
      comparison_for(model)]
  end
end
class Compare < Template
  CONTENT = CompareComposite
  def _title
    super[0..-2].push(@model.origin.name.send(@session.language))
  end
end
      end
    end
  end
end
