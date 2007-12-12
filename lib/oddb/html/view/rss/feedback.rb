#!/usr/bin/env ruby
# View::Rss::Feedback -- oddb.org -- 29.06.2007 -- hwyss@ywesee.com

require 'rss/maker'
require 'oddb/html/view/drugs/feedback'

module ODDB
  module Html
    module View
      module Rss
class FeedbackTemplate < HtmlGrid::DivTemplate
  COMPONENTS = {
    [0,0] => :feedback, 
    [0,1] => :feedback_feed_link,
  }
  def feedback(model)
    View::Drugs::FeedbackList.new([model], @session, self)
  end
  def feedback_feed_link(model)
    code = model.item.code(:cid)
    link = HtmlGrid::Link.new(:feedback_feed_link, model, @session, self)
    link.href = @lookandfeel._event_url(:feedbacks, :pzn => code)
    link
  end
end
class Feedback < HtmlGrid::Component
  HTTP_HEADERS = {
    "Content-Type"  => "application/rss+xml",
  }
  def to_html(context)
    RSS::Maker.make('2.0') { |feed|
      feed.channel.title = @lookandfeel.lookup(:feedback_feed_title)
      feed.channel.link = @lookandfeel._event_url(:home)
      feed.channel.description = @lookandfeel.lookup(:feedback_feed_description)
      feed.channel.language = @session.language
      feed.encoding = 'UTF-8'
      feed.xml_stylesheets.new_xml_stylesheet.href = @lookandfeel.resource(:css)
      size = @model.size
      @model.each_with_index { |feedback, idx|
        if(parent = feedback.item)
          item = feed.items.new_item
          item.author = "de.ODDB.org"
          title = @lookandfeel.lookup(:feedback_for, parent.name, parent.size)
          item.title = title
          
          url = @lookandfeel._event_url(:feedback, 
                                        [:pzn, parent.code(:cid),
                                         :index, size - idx])
          item.guid.content = item.link = url
          item.guid.isPermaLink = true
          item.date = feedback.time

          comp = FeedbackTemplate.new(feedback, @session, self)
          item.description = comp.to_html(context)
        end
      }
    }.to_s
  end
end
      end
    end
  end
end
