#!/usr/bin/env ruby
# Html::View::Drugs::Legend -- de.oddb.org -- 21.02.2007 -- hwyss@ywesee.com

require 'htmlgrid/composite'

module ODDB
  module Html
    module View
      module Drugs
class Legend < HtmlGrid::Composite
  COMPONENTS = {
    [0,0] => 'explain_remote',
    [0,1] => 'explain_zuzahlungsbefreit',
  }
  CSS_MAP = {
    [0,0] => 'remote',
    [0,1] => 'zuzahlungsbefreit',
  }
end
      end
    end
  end
end
