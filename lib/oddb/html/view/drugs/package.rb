#!/usr/bin/env ruby
# Html::View::Drugs::Package -- de.oddb.org -- 11.12.2006 -- hwyss@ywesee.com

require 'htmlgrid/list'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/search'

module ODDB
  module Html
    module View
      module Drugs
module PackageMethods
  def code_festbetragsgruppe(model)
    model.product.code(:festbetragsgruppe, 'DE')
  end
  def code_festbetragsstufe(model)
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
      span.css_id = "fb_#@list_index"
      span.label = true
      span
    end
  end
  def code_zuzahlungsbefreit(model)
    if((code = model.code(:zuzahlungsbefreit)) && code.value)
      @lookandfeel.lookup(:yes)
    else 
      @lookandfeel.lookup(:no)
    end
  end
end
class Part < HtmlGrid::List
  COMPONENTS = {
    [1,0] => :substance,
    [2,0] => :dose,
  }
  LEGACY_INTERFACE = false
  SORT_DEFAULT = nil
  def compose(model=@model, offset=[0,0])
    super(model.active_agents, offset)
  end
  def compose_header(offset=[0,0])
    @grid.add([@model.size, ' ', @model.unit, ' ', @model.quantity], 
              *offset)
    #resolve_offset(offset, [0,1])
    offset
  end
  def substance(model)
    model.substance.name
  end
end
class PackageInnerComposite < HtmlGrid::Composite
  include PackageMethods
  COMPONENTS = {
    [0,0] => :name, 
    [2,0] => :code_pzn, 
    [0,1] => :company, 
    [2,1] => :atc, 
    [0,2] => :price_public, 
    [2,2] => :price_festbetrag,
    [0,3] => :code_festbetragsstufe,
    [2,3] => :code_festbetragsgruppe,
    [0,4] => :code_zuzahlungsbefreit,
  }
  LABELS = true
  LEGACY_INTERFACE = false
  DEFAULT_CLASS = HtmlGrid::Value
  def atc(model)
    if(atc = model.atc)
      [atc.code, '(', atc.name, ')']
    end
  end
  def code_pzn(model)
    model.code(:cid, 'DE')
  end
  def code_zuzahlungsbefreit(model)
    @lookandfeel.lookup(model.code(:zuzahlungsbefreit) ? :yes : :no)
  end
  def company(model)
    if(company = model.company)
      company.name
    end
  end
  def price_festbetrag(model)
    model.price(:festbetrag)
  end
  def price_public(model)
    model.price(:public)
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
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => PackageInnerComposite,
    [0,4] => :parts,
  }
  CSS_ID_MAP = [ 'snapback', 'result-search', 'title' ]
  CSS_MAP = { 4 => 'divider' }
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
    key = model.parts.size > 1 ? :parts : :package
    @lookandfeel.lookup(key)
  end
  def snapback(model)
    if(query = @session.persistent_user_input(:query))
      link = HtmlGrid::Link.new(:result, model, @session, self)
      link.href = @lookandfeel._event_url(:search, [ :query, query ])
      link
    else
      link = HtmlGrid::Link.new(:home, model, @session, self)
      link.href = @lookandfeel._event_url(:home)
      link
    end
  end
end
class Package < Template
  CONTENT = PackageComposite
end
      end
    end
  end
end
