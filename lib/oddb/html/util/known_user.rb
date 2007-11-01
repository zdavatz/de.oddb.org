#!/usr/bin/env ruby
# Html::Util::KnownUser -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'sbsm/user'

module ODDB
  module Html
    module Util
class KnownUser < SBSM::User
  attr_reader :auth_session 
  PREFERENCE_KEYS = [ ]
  PREFERENCE_KEYS.each { |key|
    define_method(key) {
      remote_call(:get_preference, key) 
    }
  }
  def initialize(session)
    @auth_session = session
  end
  def allowed?(action, key=nil)
    allowed = remote_call(:allowed?, action, key)
    ODDB.logger.debug('User') {
      sprintf('%s: allowed?(%s, %s) -> %s', name, action, key, allowed)
    }
    allowed
  end
  def entity_valid?(email)
    !!(allowed?('edit', 'yus.entities') \
      && (entity = remote_call(:find_entity, email)) && entity.valid?)
  end
  def navigation
    [ :logout ]
  end
  def remote_call(method, *args, &block)
    @auth_session.send(method, *args, &block)
  rescue RangeError, DRb::DRbError => e
    ODDB.logger.error('auth') { e }
  end
  alias :method_missing :remote_call
end
    end
  end
end
