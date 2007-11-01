#!/usr/bin/env ruby
# Html::State::Drugs::Login -- de.oddb.org -- 26.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/state/login'

module ODDB
  module Html
    module State
      module Drugs
class Login < Global
  include State::Login
end
      end
    end
  end
end
