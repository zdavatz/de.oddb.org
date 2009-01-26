#!/usr/bin/env ruby
# Model -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'oddb/drugs'
require 'oddb/business/company'
require 'oddb/util/code'

class Object
  def metaclass; class << self; self; end; end
  def meta_eval &blk; metaclass.instance_eval &blk; end
end
module ODDB
  class Model
    class << self
      def all(&block)
        if(block)
          instances.each(&block)
        else
          instances
        end
      end
      def simulate_database(*names)
        meta_eval {
          define_method(:instances) {
            @instances ||= []
          }
          define_method(:find_by_code) { |criteria|
            thing = instances.find { |instance| instance.codes.any? { |code| 
              code == criteria } }
          }
          define_method(:search_by_code) { |criteria|
            thing = instances.select { |instance| instance.codes.any? { |code| 
              code == criteria } }
          }
          names.each { |name|
            define_method("find_by_#{name}") { |nme|
              instances.find { |instance| instance.send(name) == nme }
            }
            define_method("search_by_#{name}") { |nme|
              instances.select { |instance| 
                if(instance.respond_to?(name))
                  /^#{nme}/i.match(instance.send(name).to_s)
                end
              }
            }
            define_method("search_by_exact_#{name}") { |nme|
              instances.select { |instance| 
                nme.downcase == instance.send(name).to_s.downcase
              }
            }
          }
        }
        define_method(:save) {
          @saved = true
          self.class.instances.push(self).uniq!
          self
        }
        define_method(:delete) {
          self.class.instances.delete(self)
          self.class.connections.each { |name|
            method = "remove_#{self.class.singular}"
            conn = instance_variable_get(name)
            if conn.respond_to?(method)
              conn.send(method, self) 
            end
          }
          checkout
          super
        }
      end
      def find_by_uid(uid)
        ObjectSpace._id2ref(uid.to_i)
      end
      def index_keys(name, *keys)
        meta_eval {
          define_method(name) { keys }
        }
      end
    end
    alias :uid :object_id
    attr_accessor :saved
    def checkout
    end
    def saved?
      @saved
    end
    #unless(instance_methods.include?('__stub_to_yaml_properties__'))
    #  alias :__stub_to_yaml_properties__ :to_yaml_properties
      def to_yaml_properties
        super - ['@saved']
    #    __stub_to_yaml_properties__ - ['@saved']
      end
    #end
  end
  module Business
    class Company < Model
      simulate_database(:name)
    end
    class Invoice < Model
      simulate_database(:yus_name, :id)
    end
  end
  module Drugs
    class ActiveAgent < Model
      simulate_database
    end
    class Atc < Model
      simulate_database(:name)
      class << self
        def find_by_code(code)
          @instances.find { |inst| inst.code == code }
        end
        def search_by_level_and_code(level, code)
          @instances.select { |inst| 
            inst.level == level && inst.code[0,code.length] == code }
        end
      end
    end
    class Composition < Model
      simulate_database
      def checkout
        Sequence.all { |seq| seq.remove_composition self }
      end
    end
    class GalenicForm < Model
      simulate_database(:description)
    end
    class GalenicGroup < Model
      simulate_database(:name)
    end
    class Package < Model
      simulate_database(:name, :atc, :substance, :company, :product)
      def self.count
        instances.size
      end
    end
    class Part < Model
      simulate_database
      def checkout
        Package.all { |pac| pac.remove_part self }
      end
    end
    class Product < Model
      simulate_database(:name)
      index_keys(:name_keys, 'a', '4')
    end
    class Sequence < Model
      simulate_database(:product)
    end
    class Substance < Model
      simulate_database(:name)
    end
    class SubstanceGroup < Model
      simulate_database(:name)
    end
    class Unit < Model
      simulate_database(:name)
    end
  end
  module Util
    class Feedback < Model
      simulate_database 
    end
    class M10lDocument < Model
    end
  end
  module Text
    class Document < Model
      simulate_database(:source)
    end
  end
  Currency = Object.new
end
