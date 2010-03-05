#!/usr/bin/env ruby
# Html::State::PayPal::Checkout -- de.oddb.org -- 22.01.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/state/drugs/download_export'
require 'oddb/html/state/login'
require 'oddb/html/state/paypal/collect'
require 'oddb/html/state/paypal/download'
require 'oddb/html/state/paypal/redirect'
require 'oddb/html/util/known_user'
require 'oddb/html/view/ajax/json'
require 'oddb/util/yus'

module ODDB
  module Html
    module State
      module PayPal
class AjaxCheckout < Global
  VOLATILE = true
  VIEW = View::Ajax::Json
end
module Checkout
  include State::LoginMethods
  include Download
  def ajax_autofill
    email = @session.user_input(:email)
    prefs = {}
    keys = checkout_keys()
    keys.delete(:email)
    prefs.update ODDB::Util::Yus.get_preferences(email, keys)
    prefs.store(:email, email) unless prefs.empty?
    AjaxCheckout.new(@session, prefs)
  end
  def checkout
    ## its possible that we know this user already -> log them in.
    missing_keys = [:email, :pass] - @session.input_keys
    if(@session.logged_in?)
      @user = @session.user
    elsif(missing_keys.empty?)
      begin
        @user ||= @session.login
        reconsider_permissions(@user)
        @session.force_login(@user)
      rescue Yus::UnknownEntityError 
        # ignore: in this case we simply create a new user in 'create_user'
      rescue Yus::AuthenticationError
        @errors.store(:pass, create_error(:e_authentication_error, :pass, nil))
      end
    end
    input = user_input(checkout_keys(), checkout_mandatory())
    if(error?)
      self
    else
      create_user(input)
      @model.yus_name = @user.name
      @model.save
      State::PayPal::Redirect.new(@session, @model)
    end
  rescue SBSM::ProcessingError => err
    @errors.store(err.key, err)
    self
  end
  def checkout_mandatory
    keys = [ :salutation, :name_last, :name_first, ]
    unless(@session.logged_in?)
      keys.push(:email, :pass, :confirm_pass)
    end
    keys
  end
  def checkout_keys
    checkout_mandatory()
  end
  def create_user(input)
    hash = input.dup 
    ## don't store passwords in cookie vars...
    hash.delete(:confirm_pass)
    pass = hash.delete(:pass)
    ## but store the rest of the input there
    hash.each { |key, val| @session.set_cookie_input(key, val) }
    email = hash.delete(:email)
    unless(@user.is_a?(Util::KnownUser))
      @user = ODDB::Util::Yus.create_user(email, pass)
    end
    hash.delete_if { |key, value| value.to_s.empty? }
    @user.set_preferences(hash) unless(hash.empty?)
    reconsider_permissions(@user)
    @session.force_login(@user)
  rescue Yus::DuplicateNameError => e
    raise create_error(:e_duplicate_email, :email, input[:email])
  rescue RuntimeError, Yus::YusError => e
    raise create_error(e.message, :email, input[:email])
  end
end
      end
    end
  end
end
