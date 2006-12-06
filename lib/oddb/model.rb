#!/usr/bin/env ruby
# Model -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'oddb/util/multilingual'
require 'fixes/singular'
require 'facet/module/basename'

module ODDB
  class Model
    class << self
      def belongs_to(groupname, *delegators)
        attr_reader groupname
        selfname = singular
        define_method("#{groupname}=") { |group|
          old = instance_variable_get("@#{groupname}")
          if(old != group)
            if(old)
              old.send("remove_#{selfname}", self)
              old.save
            end
            if(group)
              group.send("add_#{selfname}", self)
              group.save
            end
          end
          instance_variable_set("@#{groupname}", group)
        }
        delegators.each { |delegator|
          define_method(delegator) { 
            if(group = instance_variable_get("@#{groupname}"))
              group.send(delegator)
            end
          }
        }
      end
      def connectors
        @connectors ||= []
      end
      def has_many(plural, *delegators)
        define_method(plural) {
          instance_variable_get("@#{plural}") or begin
            instance_variable_set("@#{plural}", Array.new)
          end
        }
        define_method("add_#{plural.to_s.singular}") { |inst|
          container = self.send(plural)
          unless(container.include?(inst))
            container.push(inst) 
          end
        }
        define_method("remove_#{plural.to_s.singular}") { |inst|
          self.send(plural).delete(inst)
        }
        connectors.push(plural)
        delegators.each { |key|
          define_method(key) {
            memo = []
            self.send(plural).each { |inst|
              memo.concat(inst.send(key))
            }
            memo
          }
        }
      end
      def is_coded
        has_many :codes
        define_method(:code) { |*args|
          type, country = *args
          codes.find { |code| code.is_for?(type, country || 'DE') }
        }
      end
      def multilingual(key)
        define_method(key) {
          instance_variable_get("@#{key}") or begin
            instance_variable_set("@#{key}", Util::Multilingual.new)
          end
        }
      end
      def singular
        basename.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end
    end
  end
end
