#!/usr/bin/env ruby
# Yus -- de.oddb.org -- 30.01.2008 -- hwyss@ywesee.com

require 'drb'
require 'yus/session'

module ODDB
  module Util
module Yus
  def Yus.create_user(email, pass=nil)
    Yus.server.autosession(ODDB.config.auth_domain) { |session|
      session.create_entity(email, pass)
    }
    # if there is a password, we can log in
    ODDB.server.login(email, pass) if(pass)
  end
  def Yus.get_preference(name, key)
    Yus.server.autosession(ODDB.config.auth_domain) { |session|
      session.get_entity_preference(name, key)
    }
  rescue ::Yus::YusError
    nil # return nil
  end
  def Yus.get_preferences(name, *keys)
    Yus.server.autosession(ODDB.config.auth_domain) { |session|
      session.get_entity_preferences(name, keys.flatten)
    }
  rescue ::Yus::YusError
    {} # return an empty hash
  end
  def Yus.grant(name, key, item, expires=nil)
    Yus.server.autosession(ODDB.config.auth_domain) { |session|
      session.grant(name, key, item, expires)
    }
  end
  def Yus.server
    DRb::DRbObject.new(nil, ODDB.config.auth_server)
  end
  def Yus.set_preference(name, key, value, domain=ODDB.config.auth_domain)
    Yus.server.autosession(ODDB.config.auth_domain) { |session|
      session.set_entity_preference(name, key, value, domain)
    }
  end
end
  end
end
