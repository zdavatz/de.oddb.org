#!/usr/bin/env ruby
# Html::View::Drugs::Admin::Package -- de.oddb.org -- 04.04.2008 -- hwyss@ywesee.com

require 'htmlgrid/errormessage'
require 'htmlgrid/form'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/list'

module ODDB
  module Html
    module View
      module Drugs
        module Admin
class Sequences < View::List
  include HtmlGrid::FormMethods
  COMPONENTS = {
    [0,0] => :uid,
    [1,0] => :compositions,
  }
  EVENT = :new_sequence
  OMIT_HEADER = true
  def compositions(model)
    lang = @session.language
    model.compositions.collect { |comp|
      comp.active_agents.collect { |act|
        [act.substance.name.send(lang), act.dose].join(' ')
      }.join(', ')
    }.join(' + ')
  end
  def compose_footer(offset)
    @grid.add submit(@model), *offset
  end
  def hidden_fields(context)
    super << context.hidden("uid", @container.model.uid)
  end
  def uid(model)
    link = HtmlGrid::Link.new(:uid, model, @session, self)
    link.href = @lookandfeel._event_url(:sequence, :uid => model.uid)
    link.value = model.uid
    link
  end
end
class ProductForm < HtmlGrid::Form
  include HtmlGrid::ErrorMessage
  COMPONENTS = {
    [0,0] => :name,
    [0,1] => :company,
    [1,2] => :submit, 
  }
  EVENT = :update
  LABELS = true
  LEGACY_INTERFACE = false
  SYMBOL_MAP = {
    # Product@name is used to identify imported Products 
    # and should therefore not be modified
    :name => HtmlGrid::Value,  
  }
  def init
    super
    error_message
  end
  def hidden_fields(context)
    super << context.hidden("uid", @model.uid)
  end
end
class ProductComposite < HtmlGrid::DivComposite
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => ProductForm,
    [0,4] => "sequences",
    [0,5] => :sequences,
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
  def sequences(model)
    Sequences.new(model.sequences, @session, self)
  end
  def snapback(model)
    [ super, @lookandfeel.lookup(:breadcrumb_divider),
      @lookandfeel.lookup(:product_details_for, 
                          model.name.send(@session.language)) ]
  end
end
class Product < Template
  CONTENT = ProductComposite
  def _title
    super[0..-2].push(@model.name.send(@session.language))
  end
end
        end
      end
    end
  end
end
