#!/usr/bin/env ruby
# Drugs::Substance -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Substance < Model
      multilingual :name
      has_many :active_agents
      has_many :codes
    end
  end
end
