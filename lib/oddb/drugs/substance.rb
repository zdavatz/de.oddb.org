#!/usr/bin/env ruby
# Drugs::Substance -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Substance < Model
      belongs_to :group
      has_many :active_agents
      is_coded
      multilingual :name
      def ==(other)
        super || name == other
      end
    end
  end
end
