#!/usr/bin/env ruby
# Html::State::Login -- de.oddb.org -- 26.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/viral/admin'
require 'oddb/html/view/login'
require 'yus/session'

module ODDB
  module Html
    module State
module Login
  VIEW = View::Login
  DIRECT_EVENT = :login
  def login
    reconsider_permissions(@session.login)
    trigger(:home)
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
    ].each { |key, mod|
      if(user.allowed?("login", ODDB.config.auth_domain + key))
        yield mod
      end
    }
  end
end
    end
  end
end
