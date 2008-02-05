#!/usr/bin/env ruby
# Html::Util::Session -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/config'
require 'oddb/html/state/drugs/init'
require 'oddb/html/state/global'
require 'oddb/html/state/drugs/global'
require 'oddb/html/util/lookandfeel'
require 'sbsm/redirector'
require 'sbsm/session'

module ODDB
  module Html
    module Util
class Session < SBSM::Session
  attr_reader :desired_state
  include SBSM::Redirector
  DEFAULT_FLAVOR = 'oddb'
  DEFAULT_LANGUAGE = 'de'
  DEFAULT_STATE = State::Drugs::Init
  DEFAULT_ZONE = 'drugs'
  EXPIRES = ODDB.config.session_timeout
  LF_FACTORY = LookandfeelFactory
  @@requests ||= {}
  def Session.reset_query_limit(ip = nil)
    if(ip)
      @@requests.delete(ip)
    else
      @@requests.clear
    end
  end
  def allowed?(*args)
    @user.allowed?(*args)
  rescue
    false
  end
  def limit_queries
    requests = (@@requests[remote_ip] ||= [])
    if(@state.limited?)
      requests.delete_if { |other| 
        (@process_start - other) >= ODDB.config.query_limit_phase
      }
      requests.push(@process_start)
      if(requests.size > ODDB.config.query_limit)
        @desired_state = @state
        @active_state = @state = @state.limit_state
        @state.request_path = @desired_state.request_path
      end
    end
  end
  def login
    @user = @app.login(user_input(:email), user_input(:pass))
    @user.session = self if(@user.respond_to?(:session=))
    @user
  end
  def logout
    @app.logout(@user.auth_session) if(@user.respond_to?(:auth_session))
    super
  end
  def navigation
    state.navigation
  end
  def pagelength
    100
  end
  def passed_turing_test?
    state.respond_to?(:passed_turing_test) && state.passed_turing_test
  end
  def process(request)
    @request_path = request.unparsed_uri
    @process_start = Time.now
    super
    if(!is_crawler? && lookandfeel.enabled?(:query_limit))
      limit_queries 
    end
    '' ## return empty string across the drb-border
  end
  def server_name
    super || @server_name = ODDB.config.server_name
  end
end
    end
  end
end
