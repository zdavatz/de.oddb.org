#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/state/drugs/atc_browser'

module ODDB
  module Html
    module State
class Global < SBSM::State
  attr_reader :passed_turing_test
  def atc_browser
    Drugs::AtcBrowser.new(@session, nil)
  end
  def compare
    if(code = @session.user_input(:pzn))
      _compare(code)
    end
  end
  def explain_ddd_price
    if((code = @session.user_input(:pzn)) \
       && (idx = @session.user_input(:offset)))
      _explain_ddd_price(code, idx.to_i)
    end
  end
  def explain_price
    if(code = @session.user_input(:pzn))
      _explain_price(code)
    end
  end
  def fachinfo
    if(code = @session.user_input(:pzn))
      _fachinfo(code)
    end
  end
  def feedback
    if(code = @session.user_input(:pzn))
      _feedback(code)
    end
  end
  def logout
    @session.logout
    trigger :home
  end
  def package
    if(code = @session.user_input(:pzn))
      _package(code)
    end
  end
  def package_infos
    if(code = @session.user_input(:pzn))
      _package_infos(code)
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
  def remote_infos
    if(id = @session.user_input(:uid))
      _remote_infos(id)
    end
  end
  def navigation
    []
  end
end
    end
  end
end
