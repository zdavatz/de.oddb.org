#!/usr/bin/env ruby
# Html::View::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/div'
require 'htmlgrid/span'
require 'oddb/html/view/list'
require 'oddb/html/view/search'
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
  COMPONENTS = {
    [0,0] => :product,
    [1,0] => :active_agents,
    [2,0] => :size, 
    [3,0] => :price_public,
    [4,0] => :festbetrag,
    [5,0] => :price_difference,
    [6,0] => :code_festbetragsstufe,
    [7,0] => :code_zuzahlungsbefreit,
    [8,0] => :atc,
    [9,0] => :company,
  }
  css_map = {}
  COMPONENTS.each { |key, val|
    css_map.store(key, val.to_s)
  }
  CSS_MAP = css_map
  CSS_HEAD_MAP = css_map
  EMPTY_LIST_KEY = :empty_packages
  def active_agents(model)
    link = nil
    if(code = model.code(:cid, 'DE'))
      link = HtmlGrid::Link.new(:no_active_agents, model, @session, self)
      link.href = @lookandfeel._event_url(:package, [:pzn, code.value])
    else
      link = HtmlGrid::Value.new(:no_active_agents, model, @session ,self)
    end
    agents = model.active_agents.collect { |agent|
      [
        agent.substance.name.send(@session.language), ' ',
        agent.dose, "\n",
      ]
    }
    size = agents.size
    if(size == 1)
      link.value = agents.first
    else
      link.value = @lookandfeel.lookup(:active_agents, size)
      link.css_id = "sub_#@list_index"
      link.dojo_title = agents
    end
    link
  end
  def compose_empty_list(offset)
    if(key = @model.error)
      fill_row(offset, key, 'warn')
    else
      super(offset, 'info')
    end
  end
  def festbetrag(model)
    model.price(:festbetrag)
  end
  def price_difference(model)
    if(pf = model.price(:festbetrag))
      model.price(:public) - pf
    end
  end
  def price_public(model)
    model.price(:public)
  end
  def product(model)
    span = HtmlGrid::Span.new(model, @session, self)
    span.value = model.name.send(@session.language)
    span.css_id = "cid_#@list_index"
    span.dojo_title = @lookandfeel.lookup(:pzn, model.code(:cid, 'DE'))
    span
  end
  def row_css(model, bg_flag)
    css = super
    if((code = model.code(:zuzahlungsbefreit)) && code.value)
      css = ['zuzahlungsbefreit', css].compact.join(' ')
    end
    css
  end
  def size(model)
    model.parts.collect { |part|
      parts = [part.size.to_i] 
      if(unit = part.unit)
        parts.push(unit.name.send(@session.language)
      end
      parts.compact!
      if(q = part.quantity)
        parts.push('x') unless parts.empty?
        parts.push(q)
      end
      parts.join(' ')
    }.join(' + ')
  end
end
class ResultComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => :title_found, 
    [0,1] => InlineSearch, 
    [0,2] => Packages, 
  }
  CSS_ID_MAP = ['result-found', 'result-search']
  CSS_MAP = { 2 => 'result' }
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
