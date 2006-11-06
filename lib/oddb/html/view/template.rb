#!/usr/bin/env ruby
# Html::View::Template -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'htmlgrid/divtemplate'
require 'oddb/html/view/foot'
require 'oddb/html/view/head'

module ODDB 
  module Html
    module View
class Template < HtmlGrid::DivTemplate
  FOOT = Foot
  HEAD = Head
  COMPONENTS = {
    [0,0] => :head,
    [0,1] => :content,  
    [0,2] => :foot,
  }
  def title(context)
    parts = [:html_title, @session.zone,
      *@session.state.direct_event].collect { |key| 
      @lookandfeel.lookup(key) }.compact
    context.title { parts.join(' | ') }
  end
end
    end
  end
end
