#!/usr/bin/env ruby
# Html::View::Drugs::Products -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com

require 'oddb/html/view/alpha_header'
require 'oddb/html/view/list'
require 'oddb/html/view/offset_header'
require 'oddb/html/view/search'
require 'oddb/html/view/drugs/template'

module ODDB
  module Html
    module View
      module Drugs
module ProductMethods 
  def atc(model)
    if(atc = model.atc)
      span = HtmlGrid::Span.new(model, @session, self)
      span.value = atc.code
      span.css_id = "atc_#@list_index"
      span.dojo_title = atc.name.send(@session.language)
      span
    end
  end
  def company(model)
    if(company = model.company)
      company.name.send(@session.language)
    end
  end
end
class ProductsList < View::List
  include View::AlphaHeader
  include View::OffsetHeader
  include ProductMethods
  COMPONENTS = {
    [0,0] => :product,
    [1,0] => :atc,
    [2,0] => :company,
  }
  css_map = {}
  COMPONENTS.each { |key, val|
    css_map.store(key, val.to_s)
  }
  CSS_MAP = css_map
  CSS_HEAD_MAP = css_map
  def product(model)
    link = HtmlGrid::Link.new(:product, model, @session, self)
    name = model.name.send(@session.language)
    link.value = name
    link.href = @lookandfeel._event_url(:search, :query => name)
    link
  end
  def query_key
    :range
  end
end
class ProductsComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => InlineSearch, 
    [0,1] => :products, 
  }
  CSS_ID_MAP = ['result-search']
  CSS_MAP = { 1 => 'result' }
  def products(model)
    offset = [@session.user_input(:offset).to_i, model.size].min
    ProductsList.new(model[offset, @session.pagelength], @session, self)
  end
end
class Products < Template
  CONTENT = ProductsComposite
end
      end
    end
  end
end
