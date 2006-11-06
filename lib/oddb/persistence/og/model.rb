#!/usr/bin/env ruby
# Model -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'oddb/model'
require 'oddb/persistence/og/util/multilingual'

module ODDB
  class Model
    class << self
      def multilingual(key)
        property :oddb_id
        refers_to key, Util::Multilingual
        puts "multilingual(#{self}:#{key}), defined in persistence/og/model"
        define_method(key) {
          puts "method '#{key}', defined in persistence/og/model"
          puts instance_variable_get("@#{key}")
          instance_variable_get("@#{key}") or begin
            puts "creating new Multilingual"
            instance_variable_set("@#{key}", Util::Multilingual.new)
          end
        }
      end
    end
  end
end
