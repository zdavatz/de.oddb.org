#!/usr/bin/env ruby
# Html::View::Drugs::Compare -- de.oddb.org -- 14.02.2007 -- hwyss@ywesee.com

require 'oddb/html/view/list'
require 'oddb/html/view/search'
require 'oddb/html/view/snapback'
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
  COMPONENTS = {
    [0,0] => :product,
    [1,0] => :company,
    [2,0] => :active_agents,
    [3,0] => :size, 
    [4,0] => :price_public,
    [5,0] => :difference,
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
    _compose(@model.origin, offset)
    @grid.set_row_attributes({'class' => 'origin'}, offset.at(1))
    resolve_offset(offset, self::class::OFFSET_STEP)
  end
  def difference(model)
    if(model.respond_to?(:difference))
      difference = model.difference
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
    :pzn
  end
end
class CompareComposite < HtmlGrid::DivComposite
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback,
    [0,1] => InlineSearch, 
    [0,2] => CompareList,
  }
  CSS_ID_MAP = [ 'snapback', 'result-search' ]
  CSS_MAP = { 2 => 'result' }
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
