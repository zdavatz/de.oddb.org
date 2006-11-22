#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'sbsm/state'

module ODDB
  module Html
    module State
class Global < SBSM::State
end
      module Drugs
class Global < Global
end
      end
    end
  end
end
