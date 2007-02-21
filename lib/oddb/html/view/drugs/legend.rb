#!/usr/bin/env ruby
# Html::View::Drugs::Legend -- de.oddb.org -- 21.02.2007 -- hwyss@ywesee.com

require 'htmlgrid/composite'

module ODDB
  module Html
    module View
      module Drugs
class Legend < HtmlGrid::Composite
  COMPONENTS = {}
  def init
    @css_map = @lookandfeel.legend_components.dup
    @css_map.each { |pos, key|
      components.store(pos, "explain_%s" % key)
    }
    super
  end
end
      end
    end
  end
end
