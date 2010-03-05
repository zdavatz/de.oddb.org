#!/usr/bin/env ruby
# Html::State::Paypal::Collect -- de.oddb.org -- 30.01.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/state/paypal/download'
require 'oddb/html/view/paypal/collect'

module ODDB
  module Html
    module State
      module PayPal
class Collect < Global
  VIEW = View::PayPal::Collect
  include Download
end
      end
    end
  end
end
