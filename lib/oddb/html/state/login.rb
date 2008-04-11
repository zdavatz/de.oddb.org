#!/usr/bin/env ruby
# Html::State::Login -- de.oddb.org -- 26.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/viral/admin'
require 'oddb/html/state/viral/poweruser'
require 'oddb/html/view/login'
require 'yus/session'

module ODDB
  module Html
    module State
module LoginMethods
  attr_accessor :desired_input
  def login_
    reconsider_permissions(@session.login)
    if(@desired_input)
      @session.valid_input.update @desired_input
      trigger @desired_input[:event]
    else
      @session.desired_state || trigger(:home)
    end
  rescue Yus::UnknownEntityError
    @errors.store(:email, create_error(:e_authentication_error, :email, nil))
    self
  rescue Yus::AuthenticationError
    @errors.store(:pass, create_error(:e_authentication_error, :pass, nil))
    self
  end
  private
  def reconsider_permissions(user)
    viral_modules(user) { |mod|
      self.extend(mod)
    }
  end
  def viral_modules(user)
    [ 
      ['.Admin', State::Viral::Admin],
      ['.PowerUser', State::Viral::PowerUser],
    ].each { |key, mod|
      if(user.allowed?("login", ODDB.config.auth_domain + key))
        yield mod
      end
    }
  end
end
module Login
  VIEW = View::Login
  DIRECT_EVENT = :login
  include LoginMethods
  def login
    self
  end
end
    end
  end
end
