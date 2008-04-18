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
class SequenceSelect < HtmlGrid::AbstractSelect
  def compositions(model)
    lang = @session.language
    res = model.compositions.collect { |comp|
      comp.active_agents.collect { |act|
        [act.substance.name.send(lang), act.dose].join(' ')
      }.join(', ')
    }.join(' + ')
    if(res.length > 72)
      res[0,69] << '...'
    else
      res
    end
  end
  def selection(context)
    lang = @session.language
    @selected ||= (seq = @model.sequence) && seq.uid
    res = []
    @model.product.sequences.each_with_index { |sequence, idx|
      uid = sequence.uid
      attribs = { "value" => uid }
      attribs.store("selected", 1) if(uid == selected)
      res << context.option(attribs) { compositions(sequence) }
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
          input.value = model.send(key) if model
          input
        }
      }
    end
  end
  COMPONENTS = {
    [0,0] => :delete,
    [1,0] => :multi,
    [2,0] => "x",
    [3,0] => :size,
    [4,0] => :unit,
    [5,0] => "à",
    [6,0] => :quantity,
    [7,0] => :composition,
  }
  COMPONENT_CSS_MAP = { 
    [1,0,3] => "short right",
    [6,0]   => "short right",
  }
  CSS_ID = 'parts'
  DEFAULT_CLASS = HtmlGrid::InputText
  EMPTY_LIST = true
  OMIT_HEADER = true
  input_text :multi, :size, :unit, :quantity
  def add(model)
    if(@model.empty? || @model.last.saved?)
      link = HtmlGrid::Link.new(:plus, model, @session, self)
      link.set_attribute('title', @lookandfeel.lookup(:create_part))
      link.css_class = 'create square'
      args = [ :code_cid, @session.state.model.code(:cid) ]
      url = @session.lookandfeel.event_url(:ajax_create_part, args)
      link.onclick = "replace_element('#{css_id}', '#{url}');"
      link
    end
  end
  def compose_footer(offset)
    if(@model.empty? || @model.last.saved?)
      @grid.add add(@model), *offset
    end
  end
  def composition(model)
    CompositionSelect.new(name("composition"), model, @session, self)
  end
  def delete(model)
    if(@model.size > 1)
      link = HtmlGrid::Link.new(:minus, model, @session, self)
      link.set_attribute('title', @lookandfeel.lookup(:delete))
      link.css_class = 'delete square'
      args = [ :code_cid, @session.state.model.code(:cid), :part, @list_index ]
      url = @session.lookandfeel.event_url(:ajax_delete_part, args)
      link.onclick = "replace_element('#{css_id}', '#{url}');"
      link
    end
  end
  def name(part)
    "#{part}[#@list_index]"
  end
  def unsaved(model)
    @lookandfeel.lookup(:unsaved) unless model.saved?
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
          if input.value.to_s.empty?
            input.value = @session.user_input key
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
    [2,0] => :code_cid, 
    [0,1] => :company, 
    [2,1] => :atc,
    [0,2] => :price_public, 
    [2,2] => :price_festbetrag,
    [0,3] => :code_festbetragsstufe,
    [2,3] => :code_festbetragsgruppe,
    [0,4] => :code_zuzahlungsbefreit,
    [2,4] => :sequence,
    [0,5] => :code_prescription,
    [1,6,0] => :submit, 
    [1,6,1] => :delete, 
  }
  SYMBOL_MAP = {
    :name   => HtmlGrid::InputText,
  }
  input_text :code_cid, :price_public, :price_festbetrag, :code_festbetragsstufe,
             :code_festbetragsgruppe, :equivalence_factor
  def init
    super
    error_message
  end
  def code_boolean(model, key)
    box = HtmlGrid::InputCheckbox.new("code_#{key}", model, @session, self)
    box.set_attribute('checked', (code = model.code(key)) && code.value)
    box
  end
  def delete(model)
    button = HtmlGrid::Button.new(:delete, model, @session, self)
    script = "this.form.event.value = 'delete'; this.form.submit();" 
    if(model.saved?)
      confirm = @lookandfeel.lookup(:delete_package_confirm)
      script = "if(confirm('#{confirm}')) { #{script} };"
    end
    button.onclick = script
    button
  end
  def sequence(model)
    SequenceSelect.new("sequence", model, @session, self)
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
  JAVASCRIPTS = ['admin']
end
        end
      end
    end
  end
end
