#!/usr/bin/env ruby
# Html::View::Navigation -- de.oddb.org -- 06.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/div'

module ODDB
  module Html
    module View
class Navigation < HtmlGrid::Div
  def init
    super
    @value = @lookandfeel.navigation.collect { |event|
      link = HtmlGrid::Link.new(event, @model, @session, self) 
      if(self.respond_to?(event))
        self.send(event, link)
      elsif(@session.direct_event != event)
        link.href = @lookandfeel._event_url(event)
      end
      link
    }
  end
  def contact(link)
    link.href = "http://wiki.oddb.org/wiki.php/ODDB/Kontakt"
  end
end
    end
  end
end
