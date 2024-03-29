#!/usr/bin/env ruby
# Html::View::Template -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'htmlgrid/divtemplate'
require 'htmlgrid/dojotoolkit'
require 'sbsm/time'
require 'oddb/html/view/foot'
require 'oddb/html/view/head'

module ODDB 
  module Html
    module View
class Template < HtmlGrid::DivTemplate
  include HtmlGrid::DojoToolkit::DojoTemplate
  FOOT = Foot
  HEAD = Head
  HTTP_HEADERS = {
    "Content-Type"	=>	"text/html; charset=utf-8",
    "Cache-Control"	=>	"private, no-store, no-cache, must-revalidate, post-check=0, pre-check=0",
    "Pragma"				=>	"no-cache",
    "Expires"				=>	Time.now.rfc1123,
    "P3P"						=>	"CP='OTI NID CUR OUR STP ONL UNI PRE'",
  }
  COMPONENTS = {
    [0,0] => :head,
    [0,1] => :content,  
    [0,2] => NavigationFoot,  
    [0,3] => :foot,
  }
  CSS_ID_MAP = ['head', 'content', 'navigation', 'foot']
  DOJO_DEBUG = ODDB.config.dojo_debug
  DOJO_REQUIRE = [ 'dojo.widget.Tooltip' ]
  DOJO_PARSE_WIDGETS = true
  def title(context)
    context.title { 
      _title.push(@lookandfeel.lookup(:html_owner)).join(' | ') }
  end
  def _title
    parts = [:html_title, @session.zone]
    [@session.state.direct_event].flatten.each_with_index { |part, idx|
      parts << part if((idx%2) == 0)
    }
    parts.collect { |key| 
      @lookandfeel.lookup(key) { key if(key.is_a?(String)) } }.compact
  end
  def css_links(context)
    if(@lookandfeel.enabled?(:external_css, false))
      css_link(context, @lookandfeel.resource_external(:external_css))
    else
      super
    end
  end
end
    end
  end
end
