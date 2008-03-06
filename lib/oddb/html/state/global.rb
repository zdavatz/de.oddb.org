#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/state/drugs/atc_browser'
require 'oddb/html/state/drugs/init'
require 'oddb/html/state/drugs/login'
require 'oddb/html/state/limit'
require 'oddb/html/state/register_poweruser'
require 'oddb/html/state/paypal/checkout'
require 'oddb/business/invoice'

module ODDB
  module Html
    module State
class Global < SBSM::State
  include PayPal::Checkout
  attr_reader :passed_turing_test
  LIMIT = false
  GLOBAL_MAP = {
    :atc_browser => Drugs::AtcBrowser,
    :login       => Drugs::Login,
  }
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
  def home
    State::Drugs::Init.new @session, nil
  end
  def limited?
    self.class.const_get(:LIMIT)
  end
  def limit_state
    State::Limit.new(@session, nil)
  end
  def logout
    @session.logout
    home
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
  def patinfo
    if(code = @session.user_input(:pzn))
      _patinfo(code)
    end
  end
  def proceed_poweruser
    days = @session.user_input(:days).to_i
    total = ODDB.config.prices["org.oddb.de.view.#{days}"].to_f 
    unless(days > 0 && total > 0)
      @errors.store :days, create_error(:e_missing_days, :days, 0)
      self
    else
      invoice = ODDB::Business::Invoice.new
      item = invoice.add(:poweruser, "unlimited access", days, 
                         @session.lookandfeel.lookup(:days), total / days)
      State::RegisterPowerUser.new(@session, invoice)
    end
=begin
      if(usr = @session.user_input(:pointer))
        State::User::RenewPowerUser.new(@session, invoice)
      else
        State::User::RegisterPowerUser.new(@session, invoice)
      end
    end
=end
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
  def method_missing(mth, *args)
    if(mth.to_s[0] == ?_)
      self
    else
      super
    end
  end
end
    end
  end
end
