#!/usr/bin/env ruby
# Html::View::Drugs::Admin::Package -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'htmlgrid/errormessage'
require 'htmlgrid/inputcheckbox'
require 'htmlgrid/select'
require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module View
      module Drugs
        module Admin
class CompositionSelect < HtmlGrid::AbstractSelect
  def selection(context)
    lang = @session.language
    @selected ||= (comp = @model.composition) && comp.to_s(lang)
    res = []
    @model.sequence.compositions.each_with_index { |composition, idx|
      comp = composition.to_s(lang)
      attribs = { "value" => idx }
      attribs.store("selected", 1) if(comp == selected)
      res << context.option(attribs) { comp }
    }
    res
  end
end
class Parts < List
  class << self
    def input_text(*keys)
      keys.each { |key|
        define_method(key) { |model| 
          input = HtmlGrid::Input.new(name(key), model, @session, self)
          input.value = model.send(key)
          input
        }
      }
    end
  end
  COMPONENTS = {
    [0,0] => :multi,
    [1,0] => "x",
    [2,0] => :size,
    [3,0] => :unit,
    [4,0] => "à",
    [5,0] => :quantity,
    [6,0] => :composition,
  }
  COMPONENT_CSS_MAP = { 
    [0,0,3] => "short right",
    [5,0]   => "short right",
  }
  DEFAULT_CLASS = HtmlGrid::InputText
  OMIT_HEADER = true
  input_text :multi, :size, :unit, :quantity
  def composition(model)
    CompositionSelect.new(name("composition"), model, @session, self)
  end
  def name(part)
    "#{part}[#@list_index]"
  end
end
class PackageInnerForm < Drugs::PackageInnerComposite
  class << self
    def input_text(*keys)
      keys.each { |key|
        define_method(key) { |model|
          input = HtmlGrid::InputText.new(key, model, @session, self)
          value = super
          if(value.is_a? HtmlGrid::Component)
            input.value = value.value
          else
            input.value = value
          end
          input
        }
      }
    end
  end
  include HtmlGrid::ErrorMessage
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
    [0,5] => :code_prescription,
    [1,6] => :submit, 
  }
  SYMBOL_MAP = {
    :name   => HtmlGrid::InputText,
  }
  input_text :code_pzn, :price_public, :price_festbetrag, :code_festbetragsstufe,
             :code_festbetragsgruppe, :equivalence_factor
  def code_boolean(model, key)
    box = HtmlGrid::InputCheckbox.new("code_#{key}", model, @session, self)
    box.set_attribute('checked', (code = model.code(key)) && code.value)
    box
  end
  def code_pzn(model)
    input = HtmlGrid::InputText.new(:code_cid, model, @session, self)
    input.value = super
    input
  end
  def init
    super
    error_message
  end
end
class PackageForm < HtmlGrid::DivComposite
  include HtmlGrid::FormMethods
  EVENT = :update
  COMPONENTS = {
    [0,0] => PackageInnerForm,
    [0,1] => :parts,
    [0,2] => :parts_form
  }
  CSS_MAP = { 1 => 'divider' }
  def parts(model)
    key = model.parts.size > 1 ? :parts : :package_and_substances
    @lookandfeel.lookup(key)
  end
  def parts_form(model)
    Parts.new(model.parts, @session, self)
  end
end
class PackageComposite < Drugs::PackageComposite
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => PackageForm,
  }
  CSS_MAP = { 0 => 'before-searchbar' }
  def breadcrumbs(model)
    div = @lookandfeel.lookup(:breadcrumb_divider)
    seq = HtmlGrid::Link.new(:sequence, model, @session, self)
    seq.href = @lookandfeel._event_url(:sequence, :uid => model.sequence.uid)
    prd = HtmlGrid::Link.new(:product, model, @session, self)
    prd.href = @lookandfeel._event_url(:product, :uid => model.product.uid)
    [ prd, div, seq, div ].concat super
  end
  def partline(part, idx)
    # here in the Admin-Section we want the parts displayed differently, through Parts
  end
end
class Package < Drugs::Package
  CONTENT = PackageComposite
end
        end
      end
    end
  end
end
