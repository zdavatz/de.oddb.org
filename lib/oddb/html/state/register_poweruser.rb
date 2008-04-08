#!/usr/bin/env ruby
# Html::State::RegisterPowerUser -- de.oddb.org -- 21.01.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/util/need_all_input'
require 'oddb/html/view/register_poweruser'

module ODDB
  module Html
    module State
class RegisterPowerUser < Global
  include Util::NeedAllInput
  VIEW = View::RegisterPowerUser
end
    end
  end
end
