#!/usr/bin/env ruby
# Html::View::Drugs::Legend -- de.oddb.org -- 21.02.2007 -- hwyss@ywesee.com

require 'htmlgrid/composite'

module ODDB
  module Html
    module View
      module Drugs
class Legend < HtmlGrid::Composite
  COMPONENTS = {}
  LEGACY_INTERFACE = false
  def init
    @components = @lookandfeel.legend_components.dup
    @components.each { |pos, key|
      css_map.store(pos, key.to_s.gsub(/^explain_/, ""))
    }
    super
  end
end
      end
    end
  end
end
