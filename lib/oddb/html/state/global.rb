#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'

module ODDB
  module Html
    module State
class Global < SBSM::State
  def compare
    if(code = @session.user_input(:pzn))
      _compare(code)
    end
  end
  def package
    if(code = @session.user_input(:pzn))
      _package(code)
    end
  end
  def partitioned_keys(keys)
    keys.partition { |key|
      /^[a-z]$/.match(key)
    }
  end
  def products
    _products(@session.persistent_user_input(:range))
  end
  def navigation
    [:contact, :home]
  end
end
    end
  end
end
