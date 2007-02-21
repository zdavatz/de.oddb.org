#!/usr/bin/env ruby
# Drugs::GalenicForm -- de.oddb.org -- 11.09.2006 -- hwyss@ywesee.com

require 'oddb/model'
require 'oddb/drugs/galenic_group'

module ODDB
  module Drugs
    class GalenicForm < Model
      is_coded
      multilingual :description
      belongs_to :group
      def ==(other)
        super || (!@group.nil? && @group == other.group)
      rescue
        false
      end
    end
  end
end
