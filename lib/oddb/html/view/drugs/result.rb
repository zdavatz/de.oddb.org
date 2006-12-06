#!/usr/bin/env ruby
# Html::View::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/list'
require 'htmlgrid/dojotoolkit'
require 'htmlgrid/div'
require 'htmlgrid/span'
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
    if(code = model.code(:festbetragsstufe))
      span = HtmlGrid::Span.new(model, @session, self)
      span.value = code
      link = HtmlGrid::Link.new(:festbetragsstufe, 
                                model, @session, self)
      link.href = @lookandfeel.lookup(:festbetragsstufe_url)
      span.dojo_title = [
        @lookandfeel.lookup("festbetragsstufe_#{code}"),
        link, 
      ]
      span.css_id = "fb_#{@list_index}"
      span
    end
  end
  def parts(model)
    model.parts.collect { |part| 
      part.composition.active_agents.collect { |act|
        [act.substance.name.send(@session.language), act.dose].join(' ')
      }
    }
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
    span.css_id = "cid_#{@list_index}"
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
      parts = [part.size.to_i, 
        part.unit.name.send(@session.language)].compact
      if(q = part.quantity)
        parts.push('x') unless parts.empty?
        parts.push(q)
      end
      parts.join(' ')
    }.join(' + ')
  end
  def sort_link(thkey, *rest)
    sortlink = super
    sortlink.css_id = thkey
    titlekey = thkey.sub(/^th/, "tt")
    if(title = @lookandfeel.lookup(titlekey))
      ## Inefficient - if there are performance problems, remove the
      #  next two lines and set dojo_title only where necessary
      link = HtmlGrid::Link.new(titlekey, @model, @session, self)
      # TODO: make the hrefs dynamic (latest update)
      case titlekey
      when "tt_price_public", "tt_price_difference"
        link.href = "ftp://ftp.dimdi.de/pub/amg/satzbeschr_011006.pdf"
        sortlink.dojo_title = link
      when "tt_festbetrag"
        link.href = "http://www.dimdi.de/static/de/amg/fbag/index.htm"
        sortlink.dojo_title = link
      when "tt_festbetragsstufe"
        link.href = "http://www.die-gesundheitsreform.de/glossar/festbetraege.html"
        sortlink.dojo_title = link
      when "tt_zuzahlungsbefreit"
        link.href = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/index.html"
        sortlink.dojo_title = link
      when "tt_atc"
        link.href = "http://www.whocc.no/atcddd/atcsystem.html"
        sortlink.dojo_title = link
      else
        sortlink.dojo_title = title
      end
    end
    sortlink
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
  include HtmlGrid::DojoToolkit::DojoTemplate
  CONTENT = ResultComposite
  DOJO_DEBUG = true
  DOJO_REQUIRE = [ 'dojo.widget.Tooltip' ]
  DOJO_PARSE_WIDGETS = true
end
      end
    end
  end
end
