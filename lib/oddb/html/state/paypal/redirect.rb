#!/usr/bin/env ruby
# Html::State::PayPal::Redirect -- de.oddb.org -- 23.01.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/paypal/redirect'

module ODDB
  module Html
    module State
      module PayPal
class Redirect < State::Global
  VIEW = View::PayPal::Redirect
  VOLATILE = true
end
      end
    end
  end
end
