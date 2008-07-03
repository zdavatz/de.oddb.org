#!/usr/bin/env ruby
# Drugs::Substance -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Substance < Model
      include Comparable
      belongs_to :group
      has_many :active_agents
      is_coded
      multilingual :name
      def merge(other)
        name.merge other.name
        other.active_agents.dup.each { |agent|
          agent.substance = self
          agent.save
        }
        other.delete
        save
      end
      def ==(other)
        super || name == other
      end
      def <=>(other)
        name <=> other.name
      end
    end
  end
end
