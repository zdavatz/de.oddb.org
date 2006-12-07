#!/usr/bin/env ruby
# Html::View::Head -- de.oddb.org -- 02.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/divcomposite'
require 'htmlgrid/image'
require 'htmlgrid/link'
require 'htmlgrid/span'

module ODDB
  module Html
    module View
class Head < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0]    =>  :logo,
    #[1,0,0]  =>  :sponsor,
    #[1,0,1]  =>  :welcome,
    #[0,1]    =>  :language_chooser,
    #[1,1]    =>  View::TabNavigation,
  }
  def logo(model)
    target = :home
    logo = HtmlGrid::Image.new(:logo, model, @session, self)
    if(@session.direct_event == target)
      logo
    else
      link = HtmlGrid::Link.new(target, model, @session, self)
      link.value = logo
      link.href = @lookandfeel._event_url(target)
      link
    end
  end
end
class WelcomeHead < Head
  COMPONENTS = {
    [0,0] =>  :welcome,
    [0,1] =>  :logo,
    #[1,0,0]  =>  :sponsor,
    #[0,1]    =>  :language_chooser,
    #[1,1]    =>  View::TabNavigation,
  }
  CSS_ID_MAP = ["welcome"]
  def welcome(model)
    text = @lookandfeel.lookup(:welcome_drugs).gsub("\n", "<br>")
    linktext = @lookandfeel.lookup(:welcome_drugs_link)
    span = HtmlGrid::Span.new(model, @session, self)
    span.css_id = "data_declaration"
    span.value = linktext
    span.dojo_title = [
      @lookandfeel.lookup(:drugs_fixprices), "\n",
      url_link("http://www.dimdi.de/static/de/amg/fbag/index.htm"),
      "\n\n", @lookandfeel.lookup(:drugs_copay_free), "\n", 
      url_link("http://www.dimdi.de/static/de/amg/fbag/index.htm"),
      "\n\n", @lookandfeel.lookup(:drugs_atc_codes), "\n",
      url_link("http://www.whocc.no/atcddd/"),
    ]
    parts = text.split(linktext)
    parts.zip(Array.new(parts.size - 1, span)).flatten.compact
  end
  def url_link(url)
    link = HtmlGrid::Link.new(:none, model, @session, self)
    link.href = link.value = url
    link
  end
end
    end
  end
end
