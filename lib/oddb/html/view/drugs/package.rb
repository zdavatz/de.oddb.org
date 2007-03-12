#!/usr/bin/env ruby
# Html::View::Drugs::Package -- de.oddb.org -- 11.12.2006 -- hwyss@ywesee.com

require 'oddb/html/view/list'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/google'
require 'oddb/html/view/search'
require 'oddb/html/view/snapback'

module ODDB
  module Html
    module View
      module Drugs
module PackageMethods
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
  def adjust_price(money)
    money * @lookandfeel.price_factor if(money)
  end
  def code_boolean(model, key)
    if((code = model.code(key)) && code.value)
      @lookandfeel.lookup(:yes)
    else 
      @lookandfeel.lookup(:no)
    end
  end
  def code_festbetragsgruppe(model)
    model.code(:festbetragsgruppe, 'DE')
  end
  def code_festbetragsstufe(model)
    model.code(:festbetragsstufe)
  end
  def code_prescription(model)
    code_boolean(model, :prescription)
  end
  def code_zuzahlungsbefreit(model)
    code_boolean(model, :zuzahlungsbefreit)
  end
  def ddd_prices(model)
    ddds = []
    model.ddds.each_with_index { |ddd, idx|
      if(price = adjust_price model.ddd_price(ddd))
        span = HtmlGrid::Span.new(model, @session, self)
        span.value = price
        code = model.code(:cid)
        span.css_id = "ddd_price_#{code}.#{idx}"
        args = [:pzn, code, :offset, idx]
        span.dojo_tooltip = @lookandfeel._event_url(:explain_ddd_price,
                                                    args)
                                                    
        ddds.push span
      end
    }
    val = HtmlGrid::Value.new(:ddd_prices, model, @session, self)
    val.value = ddds.zip(Array.new([ddds.size - 1, 0].max, ' / '))
    val
  end
  def price_festbetrag(model)
    @price_id ||= 0
    @price_id += 1
    span = HtmlGrid::Span.new(model, @session, self)
    span.css_id = "price_festbetrag#{@price_id}"
    span.value = adjust_price model.price(:festbetrag)
    span.dojo_title = sprintf("%s: %s",
      @lookandfeel.lookup(:price_difference), price_difference(model))
    span.label = true
    span
  end
  def price_difference(model)
    if((pf = model.price(:festbetrag)) && (pp = model.price(:public)))
      sprintf("%+1.2f", adjust_price(pp - pf))
    end
  end
  def price_public(model)
    price = adjust_price model.price(:public)
    if(!@lookandfeel.enabled?(:explain_price, false) \
       || model.is_a?(Remote::Drugs::Package))
      price
    elsif(price && (code = model.code(:cid)))
      span = HtmlGrid::Span.new(model, @session, self)
      @adjust_price ||= 0
      @adjust_price += 1
      span.value = price
      span.css_id = "adjust_price#{@adjust_price}"
      span.dojo_tooltip = @lookandfeel._event_url(:explain_price,
                                                  [:pzn, code])
      span.label = true
      span
    end
  end
  def product(model)
    if(model.is_a?(Remote::Drugs::Package))
      product_remote(model)
    else
      product_local(model)
    end
  end
  def product_local(model)
    link = nil
    if(model.atc && (code = model.code(:cid, 'DE')))
      link = HtmlGrid::Link.new(:compare, model, @session, self)
      link.href = @lookandfeel._event_url(:compare, [:pzn, code.value])
    else
      link = HtmlGrid::Span.new(model, @session, self)
    end
    link.value = model.name.send(@session.language) \
      || model.product.name.send(@session.language)
    link.css_id = "cid_#@list_index"
    link.dojo_title = @lookandfeel.lookup(:pzn, model.code(:cid, 'DE'))
    link
  end
  def product_remote(model)
    link = nil
    if(model.atc && (model.active_agents.size == 1))
      link = HtmlGrid::Link.new(:compare, model, @session, self)
      link.href = @lookandfeel._event_url(:compare_remote, 
                                          [:uid, model.uid])
    else
      link = HtmlGrid::Span.new(model, @session, self)
    end
    link.value = model.name.send(@session.language)
    link.css_id = "cid_#@list_index"
    link.dojo_title = @lookandfeel.lookup(:ean, model.code(:ean))
    link
  end
  def row_css(model, bg_flag)
    css = super
    if(model.is_a?(Remote::Drugs::Package))
      css = ['remote', css].compact.join(' ')
    elsif((code = model.code(:zuzahlungsbefreit)) && code.value)
      css = ['zuzahlungsbefreit', css].compact.join(' ')
    end
    css
  end
  def size(model)
    model.parts.collect { |part|
      parts = [part.size.to_i] 
      if(multi = part.multi)
        parts.unshift(multi, 'x')
      end
      if(unit = part.unit)
        parts.push(unit.name.send(@session.language))
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
class Part < View::List
  COMPONENTS = {
    [1,0] => :substance,
    [2,0] => :dose,
  }
  SORT_DEFAULT = nil
  def compose(model=@model, offset=[0,0])
    super(model.active_agents, offset)
  end
  def compose_header(offset=[0,0])
    part = [@model.size, ' ', @model.unit]
    if(quantity = @model.quantity)
      part.push(' x ', quantity)
    end
    @grid.add(part, *offset)
    #resolve_offset(offset, [0,1])
    offset
  end
  def substance(model)
    model.substance.name
  end
end
class PackageInnerComposite < HtmlGrid::Composite
  include PackageMethods
  include View::Google
  COMPONENTS = {
    [0,0] => :name, 
    ## google's third parameter ensures that its link is written before 
    #  the name - this allows a float: right in css to work correctly
    [1,0,0] => :google,  
    [2,0] => :code_pzn, 
    [0,1] => :company, 
    [2,1] => :atc,
    [0,2] => :price_public, 
    [2,2] => :price_festbetrag,
    [0,3] => :code_festbetragsstufe,
    [2,3] => :code_festbetragsgruppe,
    [0,4] => :code_zuzahlungsbefreit,
    [2,4] => :equivalence_factor,
    [0,5] => :code_prescription,
  }
  CSS_MAP = {
    [1,0] => 'google',
  }
  LABELS = true
  LEGACY_INTERFACE = false
  DEFAULT_CLASS = HtmlGrid::Value
  def atc(model)
    if(atc = model.atc)
      span = HtmlGrid::Span.new(model, @session, self)
      span.value = [atc.code]
      if(name = atc.name)
        span.value.push('(', name, ')')
      end
      ddds = atc.ddds
      unless(ddds.empty?)
        span.css_id = "atc"
        span.dojo_title = ddds.join("\n")
      end
			span.label = true
      span
    end
  end
  def code_festbetragsstufe(model)
    if(code = super)
      span = HtmlGrid::Span.new(model, @session, self)
      span.value = code
      link = HtmlGrid::Link.new(:festbetragsstufe, 
                                model, @session, self)
      link.href = @lookandfeel.lookup(:festbetragsstufe_url)
      span.dojo_title = [
        @lookandfeel.lookup("festbetragsstufe_#{code}"),
        link, 
      ]
      span.css_id = "fb_#@list_index"
      span.label = true
      span
    end
  end
  def code_pzn(model)
    model.code(:cid, 'DE')
  end
  def company(model)
    if(company = model.company)
      company.name
    end
  end
  def equivalence_factor(model)
    factors = model.parts.collect { |part| 
      (comp = part.composition) && comp.equivalence_factor
    }.compact
    unless(factors.empty?)
      link = HtmlGrid::Link.new(:equivalence_factor, model, 
                                @session, self)
      link.href = "http://www.gesetze-im-internet.de/fgnv/anlage_5.html"
      link.value = factors
      link.label = true
      link
    end
  end
  private
  def label(component, key=nil)
    if(component.respond_to?(:label?))
      super
    else
      lablable = HtmlGrid::Value.new(key, component, @session, self)
      lablable.value = component
      super(lablable, key)
    end
  end
end
class PackageComposite < HtmlGrid::DivComposite
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => PackageInnerComposite,
    [0,4] => :parts,
  }
  CSS_ID_MAP = [ 'snapback', 'result-search', 'title' ]
  CSS_MAP = { 0 => 'before-searchbar', 4 => 'divider' }
  def init
    model.parts.each_with_index { |part, idx|
      name = "part_#{idx}".to_sym
      components.store([0,components.size+idx], name)
      meta_eval { 
        define_method(name) { |model|
          Part.new(part, @session, self)
        }
      }
    }
    super
  end
  def name(model)
    name = [model.name]
    if(company = model.company)
      name.push(' - ', company.name)
    end
    name
  end
  def parts(model)
    key = model.parts.size > 1 ? :parts : :package_and_substances
    @lookandfeel.lookup(key)
  end
end
class Package < Template
  CONTENT = PackageComposite
  def _title
    super[0..-2].push(@model.name.send(@session.language))
  end
end
      end
    end
  end
end
