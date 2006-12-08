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
  include SBSM::Redirector
  DEFAULT_FLAVOR = 'oddb'
  DEFAULT_LANGUAGE = 'de'
  DEFAULT_STATE = State::Drugs::Init
  DEFAULT_ZONE = 'drugs'
  EXPIRES = ODDB.config.session_timeout
  LOOKANDFEEL = Lookandfeel
  def navigation
    state.navigation
  end
  def pagelength
    100
  end
end
    end
  end
end
