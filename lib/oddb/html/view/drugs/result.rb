#!/usr/bin/env ruby
# Html::View::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/list'
require 'oddb/html/view/search'
require 'oddb/html/view/drugs/template'

module ODDB
  module Html
    module View
      module Drugs
class Packages < HtmlGrid::List
  BACKGROUND_ROW = 'bg'
  BACKGROUND_SUFFIX = ''
  COMPONENTS = {
    [0,0] => :product,
    [1,0] => :doses, 
    [2,0] => :size, 
    [3,0] => :price_public,
    [4,0] => :festbetrag,
    [5,0] => :price_difference,
    [6,0] => :festbetragsstufe,
    [7,0] => :zuzahlungsbefreit,
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
  LEGACY_INTERFACE = false
  SORT_DEFAULT = nil
  def atc(model)
    if(atc = model.atc)
      atc.code
    end
  end
  def company(model)
    if(company = model.company)
      company.name.send(@session.language)
    end
  end
  def doses(model)
    model.doses.join(' + ')
  end
  def daily_cost(model)
    if(atc = model.atc)
    end
  end
  def festbetrag(model)
    model.price(:festbetrag)
  end
  def festbetragsstufe(model)
    model.code(:festbetragsstufe)
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
    model.name.send(@session.language)
  end
  def size(model)
    model.parts.collect { |part|
      parts = [part.size.to_i, 
        part.unit.name.send(@session.language)].compact
      if(q = part.quantity)
        parts.push('x') unless parts.empty?
        parts.push(q)
      end
      parts.join(' ')
    }.join(' + ')
  end
  def zuzahlungsbefreit(model)
    if((code = model.code(:zuzahlungsbefreit)) && code.value)
      @lookandfeel.lookup(:yes)
    end
  end
end
class ResultComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => InlineSearch, 
    [0,1] => :packages, 
  }
  CSS_ID_MAP = ['result-search']
  def packages(model)
    packages = model.packages
    Packages.new(model.packages, @session, self)
  end
end
class Result < Template
  CONTENT = ResultComposite
end
      end
    end
  end
end
