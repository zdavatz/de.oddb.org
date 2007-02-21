#!/usr/bin/env ruby
# Html::View::Google -- de.oddb.org -- 21.02.2007 -- hwyss@ywesee.com

module ODDB
  module Html
    module View
module Google
  def google(model)
    @google_id ||= 0
    @google_id += 1
    link = HtmlGrid::Link.new(:google, model, @session, self)
    link.css_id = "google_%i" % @google_id
    name = model.name.send(@session.language)
    link.href = "http://www.google.de/search?q=%s" % name
    link.dojo_title = @lookandfeel.lookup(:google, name)
    link.css_class = 'square google'
    link.label = false
    link
  end
end
    end
  end
end
