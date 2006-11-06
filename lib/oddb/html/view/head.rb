#!/usr/bin/env ruby
# Html::View::Head -- de.oddb.org -- 02.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/divcomposite'
require 'htmlgrid/image'
require 'htmlgrid/link'

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
    target = :home_drugs
    logo = HtmlGrid::Image.new(:logo, model, @session, self)
    if(@session.direct_event == target)
      logo
    else
      link = HtmlGrid::Link.new(target, model, @session, self)
      link.value = logo
      link
    end
  end
end
    end
  end
end
