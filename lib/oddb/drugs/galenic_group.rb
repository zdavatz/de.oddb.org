#!/usr/bin/env ruby
# Drugs::GalenicGroup -- de.oddb.org -- 21.02.2007 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class GalenicGroup < Model
      multilingual :name
      has_many :galenic_forms
      def initialize(groupname, language='de')
        name.send("%s=" % language, groupname)
      end
    end
  end
end
