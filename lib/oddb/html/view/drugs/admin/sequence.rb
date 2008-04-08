#!/usr/bin/env ruby
# Html::View::Drugs::Admin::Package -- de.oddb.org -- 04.04.2008 -- hwyss@ywesee.com

require 'htmlgrid/errormessage'
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
    [0,0] => :substance,
    [1,0] => :dose,
  }
  COMPONENT_CSS_MAP = { [1,0] => 'short right' }
  DEFAULT_CLASS = HtmlGrid::InputText
  OMIT_HEADER = true
  STRIPED_BG = false
  def dose(model)
    input = HtmlGrid::InputText.new(name("dose"), model, @session, self)
    input.value = model.dose.to_s
    input
  end
  def name(part)
    "#{part}[#{@container.list_index}][#@list_index]"
  end
  def substance(model)
    input = HtmlGrid::InputText.new(name("substance"), model, @session, self)
    input.value = model.substance.name.send(@session.language)
    input
  end
end
class Compositions < View::List
  COMPONENTS = { [0,0] => :composition }
  OFFSET_STEP = [1,0]
  OMIT_HEADER = true
  attr_reader :list_index
  def composition(model)
    ActiveAgents.new(model.active_agents, @session, self)
  end
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
    [1,5] => :submit, 
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
  def fachinfo_link(model)
    super model.packages.first
  end
  def patinfo_link(model)
    super model.packages.first
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
  def _title
    super[0..-2].push(@model.name.send(@session.language))
  end
end
        end
      end
    end
  end
end
