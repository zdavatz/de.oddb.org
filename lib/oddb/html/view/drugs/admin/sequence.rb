#!/usr/bin/env ruby
# Html::View::Drugs::Admin::Package -- de.oddb.org -- 04.04.2008 -- hwyss@ywesee.com

require 'htmlgrid/errormessage'
require 'htmlgrid/button'
require 'htmlgrid/divlist'
require 'htmlgrid/form'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/drugs/package'
require 'oddb/html/view/list'

module ODDB
  module Html
    module View
      module Drugs
        module Admin
class ActiveAgents < View::List
  COMPONENTS = {
    [0,0] => :delete,
    [1,0] => :substance,
    [2,0,0] => :dose,
    [2,0,1] => :unsaved,
  }
  COMPONENT_CSS_MAP = { [2,0] => 'short right' }
  DEFAULT_CLASS = HtmlGrid::InputText
  OMIT_HEADER = true
  STRIPED_BG = false
  def add(model)
    link = HtmlGrid::Link.new(:plus, model, @session, self)
    link.set_attribute('title', @lookandfeel.lookup(:create_active_agent))
    link.css_class = 'create square'
    args = [ :uid, @session.state.model.uid, :composition, composition ]
    url = @session.lookandfeel.event_url(:ajax_create_active_agent, args)
    link.onclick = "edit_compositions('#{css_id}', '#{url}');"
    link
  end
  def compose_footer(offset)
    if(@model.empty? || @model.last)
      @grid.add add(@model), *offset
      offset[0] += 1
      @grid.add delete_composition(@model), *offset
      @grid.add_style 'right', *offset
      @grid.set_colspan offset.at(0), offset.at(1)
    end
  end
  def composition
    @container ? @container.list_index : @session.user_input(:composition)
  end
  def css_id
    @css_id ||= "active-agents-#{composition}"
  end
  def delete(model)
    unless(@model.first.nil?)
      link = HtmlGrid::Link.new(:minus, model, @session, self)
      link.set_attribute('title', @lookandfeel.lookup(:delete))
      link.css_class = 'delete square'
      args = [ :uid, @session.state.model.uid, :composition, composition, 
               :active_agent, @list_index ]
      url = @session.lookandfeel.event_url(:ajax_delete_active_agent, args)
      link.onclick = "edit_compositions('#{css_id}', '#{url}');"
      link
    end
  end
  def delete_composition(model)
    link = HtmlGrid::Link.new(:delete_composition, model, @session, self)
    link.css_class = 'ajax'
    args = [ :uid, @session.state.model.uid, :composition, composition ]
    url = @session.lookandfeel.event_url(:ajax_delete_composition, args)
    link.onclick = "edit_compositions('composition-list', '#{url}');"
    link
  end
  def dose(model)
    input = HtmlGrid::InputText.new(name("dose"), model, @session, self)
    input.value = model.dose.to_s if model
    input
  end
  def name(part)
    "#{part}[#{composition}][#@list_index]"
  end
  def substance(model)
    input = HtmlGrid::InputText.new(name("substance"), model, @session, self)
    input.value = model.substance.name.send(@session.language) if model
    input
  end
  def unsaved(model)
    @lookandfeel.lookup(:unsaved) if model.nil?
  end
end
class CompositionList < HtmlGrid::DivList
  COMPONENTS = { [0,0] => :composition }
  OFFSET_STEP = [1,0]
  OMIT_HEADER = true
  attr_reader :list_index
  def add(model)
    link = HtmlGrid::Link.new(:create_composition, model, @session, self)
    link.css_class = 'ajax'
    args = [ :uid, @session.state.model.uid ]
    url = @session.lookandfeel.event_url(:ajax_create_composition, args)
    link.onclick = "edit_compositions('composition-list', '#{url}');"
    link
  end
  def compose
    super
    comp = @model.last
    @grid.push [add(@model)] if comp.nil? || !comp.active_agents.compact.empty?
  end
  def composition(model)
    ActiveAgents.new(model.active_agents, @session, self)
  end
end
class Compositions < HtmlGrid::DivComposite
  COMPONENTS = { [0,0] => CompositionList }
  CSS_ID = 'composition-list'
end
class Packages < View::List
  include PackageMethods
  COMPONENTS = {
    [0,0] => :pzn,
    [1,0] => :name,
    [2,0] => :size,
  }
  OMIT_HEADER = true
  STRIPED_BG = true
  def pzn(model)
    code = model.code(:cid)
    link = HtmlGrid::Link.new(:cid, model, @session, self)
    link.href = @lookandfeel._event_url(:package, :pzn => code)
    link.value = code
    link
  end
end
class SequenceInnerForm < HtmlGrid::Composite
  include HtmlGrid::ErrorMessage
  include PackageMethods
  COLSPAN_MAP = {
    [1,3] => 3,
    [1,4] => 3,
  }
  COMPONENTS = {
    [0,0] => :atc,
    [2,0] => :show_atc_name,
    [0,1] => :registration,
    [1,2,0] => :fachinfo_link,
    [1,2,1] => :patinfo_link,
    [0,3] => :fi_url,
    [0,4] => :pi_url,
    [1,5,0] => :submit, 
    [1,5,1] => :delete, 
  }
  COMPONENT_CSS_MAP = {
    [1,3] => 'url',
    [1,4] => 'url',
  }
  LABELS = true
  LEGACY_INTERFACE = false
  def init
    if(@session.errors.any? { |err| err.message == "e_unknown_atc" })
      components.store([2,0], :atc_name)
    end
    super
    error_message
  end
  def atc_name(model)
    HtmlGrid::InputText.new(:atc_name, model, @session, self)
  end
  def delete(model)
    button = HtmlGrid::Button.new(:delete, model, @session, self)
    button.onclick = "if(confirm('#{@lookandfeel.lookup(:delete_sequence_confirm)}')) { this.form.event.value = 'delete'; this.form.submit(); }"
    button
  end
  def fachinfo_link(model)
    if pac = model.packages.first
      super pac
    end
  end
  def patinfo_link(model)
    if pac = model.packages.first
      super pac
    end
  end
  def show_atc_name(model)
    if(atc = model.atc)
      value = HtmlGrid::Value.new(:atc_name, atc, @session, self)
      value.value = atc.name.de
      value
    end
  end
end
class SequenceForm < HtmlGrid::DivForm
  COMPONENTS = {
    [0,0] => SequenceInnerForm,
    [0,1] => "compositions",
    [0,2] => :compositions,
  }
  CSS_ID_MAP = { 2 => 'compositions' }
  CSS_MAP = { 1 => 'divider' }
  EVENT = :update
  def compositions(model)
    Compositions.new(model.compositions, @session, self)
  end
  def hidden_fields(context)
    super << context.hidden("uid", @model.uid)
  end
end
class SequenceComposite < HtmlGrid::DivComposite
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => SequenceForm,
    [0,4] => "packages_admin",
    [0,5] => :packages,
  }
  CSS_ID_MAP = [ 'snapback', 'result-search', 'title' ]
  CSS_MAP = { 0 => 'before-searchbar', 4 => 'divider' }
  def name(model)
    name = [model.name]
    if(company = model.company)
      name.push(' - ', company.name)
    end
    name
  end
  def packages(model)
    Packages.new(model.packages, @session, self)
  end
  def snapback(model)
    div = @lookandfeel.lookup(:breadcrumb_divider)
    prd = HtmlGrid::Link.new(:product, model, @session, self)
    prd.href = @lookandfeel._event_url(:product, :uid => model.product.uid)
    [ super, div, prd, div,
      @lookandfeel.lookup(:sequence_details_for, 
                          model.name.send(@session.language)) ]
  end
end
class Sequence < Template
  CONTENT = SequenceComposite
  JAVASCRIPTS = ['sequence']
  def _title
    super[0..-2].push(@model.name.send(@session.language))
  end
end
        end
      end
    end
  end
end
