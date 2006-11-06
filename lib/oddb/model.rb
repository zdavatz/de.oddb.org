#!/usr/bin/env ruby
# Model -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'oddb/util/multilingual'
require 'facet/string/singular'

module ODDB
  class Model
    class << self
      def connectors
        @connectors ||= []
      end
      def has_many(plural)
        define_method(plural) {
          instance_variable_get("@#{plural}") or begin
            instance_variable_set("@#{plural}", Array.new)
          end
        }
        define_method("add_#{plural.to_s.singular}") { |inst|
          self.send(plural).push(inst)
        }
        define_method("remove_#{plural.to_s.singular}") { |inst|
          self.send(plural).delete(inst)
        }
        connectors.push(plural)
      end
      def multilingual(key)
        define_method(key) {
          instance_variable_get("@#{key}") or begin
            instance_variable_set("@#{key}", Util::Multilingual.new)
          end
        }
      end
    end
  end
end
