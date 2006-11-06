#!/usr/bin/env ruby
# Html::View::Foot -- de.oddb.org -- 02.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/divcomposite'

module ODDB
  module Html
    module View
class Foot < HtmlGrid::DivComposite
  COMPONENTS = { 
    [0,0] => :copyright, 
  }
  def copyright(model)
    [ lgpl_license(model), ', ', Time.now.year, cpr_link(model),
      oddb_version(model) ]
  end
  def cpr_link(model)
    link = HtmlGrid::Link.new(:cpr_link, model, @session, self)
    link.href = 'http://www.ywesee.com'
    link
  end
  def lgpl_license(model)
    link = HtmlGrid::Link.new(:lgpl_license, model, @session, self)
    link.href = 'http://www.gnu.org/copyleft/lesser.html'
    link
  end
  def oddb_version(model)
    link = HtmlGrid::Link.new(:oddb_version, model, @session, self)
    link.href = 'http://scm.ywesee.com/?p=de.oddb.org;a=summary'
    link.set_attribute('title', ODDB_VERSION)
    link
  end
end
    end
  end
end
