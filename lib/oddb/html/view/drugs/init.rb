#!/usr/bin/env ruby
# Html::View::Drugs::Init -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/template'
require 'oddb/html/view/drugs/search'
require 'oddb/html/view/google_ads'
require 'oddb/html/view/rss_preview'

module ODDB
  module Html
    module View
      module Drugs
class Init < Template
  COMPONENTS = {
    [0,0] => :head,
    [0,1] => :sidebar_left,
    [0,2] => :sidebar_right,
    [0,3] => :content,  
    [0,4] => NavigationFoot,  
    [0,5] => :foot,
  }
  CONTENT = Search
  CSS_MAP = { 1 => 'sidebar lefthand', 2 => 'sidebar righthand' }
  CSS_ID_MAP = { 0 => 'head', 3 => 'home-search', 
                 4 => 'navigation', 5 => 'foot' }
  HEAD = WelcomeHead
  def sidebar_left(model)
    if(@lookandfeel.enabled?(:google_ads) && !@session.logged_in?)
      GoogleAds.new 
    end
  end
  def sidebar_right(model)
    if(@lookandfeel.enabled?(:feedback_rss))
      RssFeedbacks.new ODDB::Util::Feedback.newest, @session, self
    end
  end
  def other_html_headers(context)
    headers = super 
    if(@lookandfeel.enabled?(:feedback_rss))
      url = [ 'http:/', @session.server_name, 'rss', 
              @session.language, "feedback.rss" ].join('/')
      headers << context.link(:href => url, :type => "application/rss+xml",
                              :title => 'feedback.rss', :rel => "alternate")
    end
    headers
  end
end
      end
    end
  end
end
