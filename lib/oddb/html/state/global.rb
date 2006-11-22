#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'

module ODDB
  module Html
    module State
class Global < SBSM::State
  def search
    _search(@session.persistent_user_input(:query))
  end
end
    end
  end
end
