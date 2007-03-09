#!/usr/bin/env ruby
# Model -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'oddb/util/multilingual'
require 'fixes/singular'
require 'facet/module/basename'

module ODDB
  class Model
    class Predicate
      attr_reader :action, :type, :delegators
      def initialize(action, type, *delegators)
        raise "unknown predicate type: #{type}" unless respond_to?(type)
        @action, @type, @delegators = action, type, delegators
      end
      def cascade(action, next_level)
        if(next_level.is_a?(Array))
          next_level.each { |element| 
            cascade(action, element)
          }
        else
          next_level.send(action) if(next_level.respond_to?(action))
        end
      end
      def delegate(action, next_level)
      end
      def execute(action, object)
        if(action == @action)
          @delegators.each { |delegator|
            self.send(@type, action, object.send(delegator))
          }
        end
      end
    end
    class << self
      def belongs_to(groupname, *predicates)
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
        predicates.each { |predicate|
          if(predicate.action == :method_missing)
            predicate.delegators.each { |key|
              define_method(key) { 
                if(group = instance_variable_get("@#{groupname}"))
                  group.send(key)
                end
              }
            }
          else
            predicate.delegators.push(groupname)
            self.predicates.push(predicate)
          end
        }
      end
      def connectors
        @connectors ||= []
      end
      def delegates(*delegators)
        Predicate.new(:method_missing, :delegate, *delegators)
      end
      def has_many(plural, *predicates)
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
        predicates.each { |predicate|
          if(predicate.type == :delegate)
            predicate.delegators.each { |key|
              define_method(key) {
                self.send(plural).collect { |inst|
                  inst.send(key)
                }.flatten
              }
            }
          else
            predicate.delegators.push(plural)
            self.predicates.push(predicate)
          end
        }
      end
      def on_delete(action, *delegators)
        Predicate.new(:delete, action, *delegators)
      end
      def on_save(action, *delegators)
        Predicate.new(:save, action, *delegators)
      end
      def predicates
        @predicates ||= []
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
        define_method(:to_s) { 
          self.send(key).to_s
        }
      end
      def singular
        basename.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end
      def serialize(key)
      end
    end
    def delete
      self.class.predicates.each { |predicate|
        predicate.execute(:delete, self)
      }
      self
    end
    def save
      self.class.predicates.each { |predicate|
        predicate.execute(:save, self)
      }
      self
    end
  end
end
