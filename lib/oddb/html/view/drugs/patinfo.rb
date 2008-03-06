#!/usr/bin/env ruby
# Html::View::Drugs::Patinfo -- de.oddb.org -- 30.10.2007 -- hwyss@ywesee.com

require 'oddb/html/view/document'
require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module View
      module Drugs
class PatinfoComposite < HtmlGrid::DivComposite
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => :chapters,
    [0,4] => :document,
  }
  CSS_ID_MAP = [ 'snapback', 'result-search', 'title', 'chapters' ]
  CSS_MAP = { 0 => 'before-searchbar' }
  def document(model)
    if((fi = model.patinfo) && (doc = fi.send(@session.language)))
      Document.new(doc, @session, self)
    end
  end
  def chapters(model)
    if((fi = model.patinfo) && (doc = fi.send(@session.language)))
      ChapterNames.new(:patinfo, doc, @session, self)
    end
  end
end
class Patinfo < Package
  CONTENT = PatinfoComposite
end
      end
    end
  end
end
