#!/usr/bin/env ruby
# Html::State::Paypal::Collect -- de.oddb.org -- 30.01.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/paypal/collect'

module ODDB
  module Html
    module State
      module PayPal
class Collect < Global
  VIEW = View::PayPal::Collect
  def collect
    @model = Business::Invoice.find_by_id(@session.user_input(:invoice))
    state = self
    # since the permissions of the current User may have changed, we
    # need to reconsider his viral modules
    if((user = @session.user).is_a?(Util::KnownUser))
      reconsider_permissions(user)
    end
    if(@session.allowed?('view', ODDB.config.auth_domain))
      if(des = @session.desired_state)
        state = des
      else
        state.extend Drugs::Events
      end
    end
    state
  end
end
      end
    end
  end
end
