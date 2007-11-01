#!/usr/bin/env ruby
# Html::View::Navigation -- de.oddb.org -- 06.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/div'

module ODDB
  module Html
    module View
class Links < HtmlGrid::Component
  def init
    super
    @value = links(link_keys)
  end
  def links(keys)
    current = @session.direct_event
    keys.collect { |event|
      link = HtmlGrid::Link.new(event, @model, @session, self) 
      if(self.respond_to?(event))
        self.send(event, link)
      elsif(current != event)
        link.href = @lookandfeel._event_url(event)
      end
      link
    }
  end
end
class CountryLinks < Links
  def link_keys
    country, = @session.server_name.split('.')
    ptrn = /_#{country}$/
    [:oddb_ch, :oddb_de, :oddb_chde].reject { |key| 
      ptrn.match(key.to_s) }
  end
  def oddb_ch(link)
    link.href = "http://ch.oddb.org/de/"
  end
  def oddb_chde(link)
    link.href = "http://chde.oddb.org/"
  end
  def oddb_de(link)
    link.href = "http://de.oddb.org/"
  end
end
class HelpLinks < Links
  def contact(link)
    link.href = "http://wiki.oddb.org/wiki.php/ODDB/Kontakt"
  end
  def link_keys
    user_navigation.concat [:contact, :home]
  end
  def user_navigation
    nav = @session.user.navigation 
    if(nav.empty?)
      [:login]
    else
      nav
    end
  end
end
class Navigation < Links
  def link_keys
    @lookandfeel.navigation
  end
end
    end
  end
end
