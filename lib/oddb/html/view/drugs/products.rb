#!/usr/bin/env ruby
# Html::View::Drugs::Products -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com

require 'oddb/html/view/alpha_header'
require 'oddb/html/view/offset_header'
require 'oddb/html/view/search'
require 'oddb/html/view/drugs/result'
require 'oddb/html/view/drugs/template'

module ODDB
  module Html
    module View
      module Drugs
class ProductsList < Packages
  include View::AlphaHeader
  include View::OffsetHeader
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
    link.css_id = "cid_#{@list_index}"
    link.dojo_title = @lookandfeel.lookup(:pzn, model.code(:cid, 'DE'))
    link.href = @lookandfeel._event_url(:search, :query => name)
    link
  end
end
class ProductsComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => InlineSearch, 
    [0,1] => :products, 
  }
  CSS_ID_MAP = ['result-search']
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
