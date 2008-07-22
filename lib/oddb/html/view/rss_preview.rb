#!/usr/bin/env ruby
# Html::View::RssPreview -- de.oddb.org -- 12.12.2007 -- hwyss@ywesee.com

require 'htmlgrid/divcomposite'
require 'htmlgrid/divlist'
require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module View
class RssPreview < HtmlGrid::DivComposite
  CSS_MAP = ['heading']
  def rss_image(model)
    if(link = title(model))
      img = HtmlGrid::Image.new(:rss_img, model, @session, self)
      img.attributes['src'] = @lookandfeel.resource_global(:rss_img)
      link.value = img
      link
    end
  end
end
class RssFeedbackList < HtmlGrid::DivList
  include Drugs::PackageMethods
  COMPONENTS = {
    [0,0] => :heading,
  }
  def heading(model)
    if(parent = model.item)
      link = HtmlGrid::Link.new(:feedback, model, @session, self)
      link.href = @lookandfeel._event_url(:feedback, :pzn => parent.code(:cid))
      link.value = @lookandfeel.lookup :feedback_preview, parent.name, size(parent)
      link
    end
  end
end
class RssFeedbacks < RssPreview
  COMPONENTS = {
    [0,0] => :rss_image,
    [1,0] => :title,
    [0,1] => RssFeedbackList,
  }
  def title(model)
    if(feedback = model.first)
      link = HtmlGrid::Link.new(:feedback_feed_title, model, @session, self)
      link.href = url = [ 'http:/', @session.server_name, 'rss', 
                          @session.language, "feedback.rss" ].join('/')
      link.css_class = 'rss-title'
      link
    end
  end
end
    end
  end
end
