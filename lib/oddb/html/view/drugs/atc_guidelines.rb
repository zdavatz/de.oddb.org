#!/usr/bin/env ruby
# Html::View::Drugs::AtcGuidelines -- de.oddb.org -- 09.03.2007 -- hwyss@ywesee.com

require 'htmlgrid/divlist'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/list'

module ODDB
  module Html
    module View
      module Drugs
module AtcMethods
  def atc_description(atc)
    sprintf("%s - %s", atc.code, atc.name.send(@session.language))
  end
end
class Ddds < View::List
  COMPONENTS = {
    [0,0] => :administration, 
    [1,0] => :dose, 
    [2,0] => :comment, 
  }
  CSS_MAP = {
    [1,0] => 'doses',
  }
  DEFAULT_CLASS = HtmlGrid::Value
  SORT_HEADER = false
  def administration(model)
    ad = model.administration
    @lookandfeel.lookup("administration_#{ad}") { ad }
  end
end
class AtcGuidelineList < HtmlGrid::DivList
  include AtcMethods
  COMPONENTS = {
    [0,0] => :atc_description, 
    [1,0] => :guidelines, 
    [2,0] => :ddd_guidelines, 
    [3,0] => :ddds, 
  }
  @@atc_re = /\b[A-Z]\d{2}([A-Z]([A-Z](\d{2})?)?)?\b/
  def atc_description(model)
    div(super, "atc groupheader")
  end
  def div(value, klass="atc")
    unless(value.to_s.strip.empty?)
      div = HtmlGrid::Div.new(value, @session, self)
      div.value = value.gsub(@@atc_re) { |match|
        sprintf("<a href='%s'>%s</a>", 
                @lookandfeel._event_url(:ddd, [:code, match]), match)
      }
      div.css_class = klass
      div
    end
  end
  def guidelines(model)
    div(model.guidelines.en)
  end
  def ddd_guidelines(model)
    div(model.ddd_guidelines.en, "atc ddd")
  end
  def ddds(model)
    ddds = model.ddds
    unless(ddds.empty?)
      Ddds.new(ddds, @session, self)
    end
  end
end
class AtcGuidelinesComposite < HtmlGrid::DivComposite
  include AtcMethods
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :atc_description,
    [0,3] => :atcs,
  }
  CSS_ID_MAP = [ 'snapback', 'result-search', 'title' ]
  CSS_MAP = { 0 => 'before-searchbar'}
  def atcs(model)
    list = [model]
    while(model = model.parent)
      list.unshift(model)
    end
    AtcGuidelineList.new(list, @session, self)
  end
end
class AtcGuidelines < Template
  CONTENT = AtcGuidelinesComposite
end
      end
    end
  end
end
