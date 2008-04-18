#!/usr/bin/env ruby
# Html::State::Limit -- de.oddb.org -- 20.12.2007 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/state/login'
require 'oddb/html/view/limit'

module ODDB
  module Html
    module State
class Limit < Global
  include State::LoginMethods
  VIEW = View::Limit
end
    end
  end
end
