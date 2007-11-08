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
    [0,0] => :user,
    [0,1] => :logo,
  }
  CSS_ID_MAP = ["user"]
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
  def user(model)
    user = @session.user
    if(user.is_a? Util::KnownUser)
      @lookandfeel.lookup(:welcome_user, user.name)
    end
  end
end
class WelcomeHead < Head
  COMPONENTS = {
    [0,0] => :user,
    [0,1] => :welcome,
    [0,2] => :logo,
  }
  CSS_ID_MAP = ["user", "welcome"]
  def welcome(model)
    link = HtmlGrid::Link.new(:welcome_drugs, model, @session, self)
    link.value.gsub!("\n", "<br>")
    link.href = @lookandfeel.lookup(:screencast_url)
    span = HtmlGrid::Span.new(model, @session, self)
    span.css_id = "data_declaration"
    span.value = @lookandfeel.lookup(:welcome_data_declaration)
    span.dojo_title = [
      @lookandfeel.lookup(:drugs_fixprices), "\n",
      url_link("http://www.dimdi.de/static/de/amg/fbag/index.htm"),
      "\n\n", @lookandfeel.lookup(:drugs_copay_free), "\n", 
      url_link("http://www.bkk.de/bkk/powerslave,id,1081,nodeid,.html"),
      "\n\n", @lookandfeel.lookup(:drugs_atc_codes), "\n",
      url_link("http://www.whocc.no/atcddd/"),
    ]
    [ link, span ]
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
