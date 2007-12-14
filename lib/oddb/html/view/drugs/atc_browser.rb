#!/usr/bin/env ruby
# Html::View::Drugs::AtcBrowser -- de.oddb.org -- 13.12.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/template'
require 'oddb/html/view/list'
require 'oddb/html/view/search'

module ODDB
  module Html
    module View
      module Drugs
class AtcList < View::List
  COMPONENTS = {
    [0,0] => :name,
    [1,0] => :ddd_link,
  }
  OMIT_HEADER = true
  STRIPED_BG = false
  #CSS_MAP = { [1,0] => 'atc' }
  def ddd_link(model)
    if(model.interesting?)
      link = HtmlGrid::Link.new(:who_ddd, model, @session, self)
      link.href = @lookandfeel._event_url(:ddd, [:code, model.code])
      link.css_class = 'who-ddd square'
      link
    end
  end
  def name(model)
    css_map.update( [0,0] => "atc level#{model.level} browser", 
                    [1,0] => "atc level#{model.level}" )
    value = if(name = model.name.send(@session.language))
              [name, " (" << model.code.to_s << ")"]
            else
              model.code
            end
    search_level = model.level > 1 && (code = @session.user_input(:code)) \
                      && /^#{model.code}/.match(code) || model.level == 5
    if search_level && model.packages.empty?
      return value
    end
    link = HtmlGrid::Link.new(model.code, model, @session, self)
    if search_level
      link.href = @lookandfeel._event_url(:search, 
                                          [:query, model.code, :dstype, :compare])
      link.css_class = 'search'
    else
      link.href = @lookandfeel._event_url(:atc_browser, :code => model.code)
    end
    link.value = value
    link
  end
end
class AtcComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => InlineSearch, 
    [0,1] => "atc_browser",
    [0,2] => AtcList, 
  }
  CSS_ID_MAP = ['result-search', 'title']
  CSS_MAP = { 1 => 'result' }
end
class AtcBrowser < Template
  CONTENT = AtcComposite
end
      end
    end
  end
end
