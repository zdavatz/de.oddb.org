#!/usr/bin/env ruby
# Html::View::Composite -- de.oddb.org -- 14.02.2007 -- hwyss@ywesee.com

require 'htmlgrid/divcomposite'

module ODDB
  module Html
    module View
module Snapback
  def snapback(model)
    if(query = @session.persistent_user_input(:query))
      link = HtmlGrid::Link.new(:result, model, @session, self)
      link.href = @lookandfeel._event_url(:search, [ :query, query ])
      link
    else
      link = HtmlGrid::Link.new(:home, model, @session, self)
      link.href = @lookandfeel._event_url(:home)
      link
    end
  end
end
    end
  end
end
