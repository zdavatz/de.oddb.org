#!/usr/bin/env ruby
# Model -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

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
          self.class.instances.push(self).uniq!
        }
        define_method(:delete) {
          self.class.instances.delete(self)
        }
      end
      def index_keys(name, *keys)
        meta_eval {
          define_method(name) { keys }
        }
      end
    end
  end
  module Business
    class Company
      simulate_database(:name)
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
      end
    end
    class Composition < Model
      simulate_database
    end
    class GalenicForm < Model
      simulate_database(:description)
    end
    class Package < Model
      simulate_database(:name, :atc, :substance)
    end
    class Part < Model
      simulate_database
    end
    class Product < Model
      simulate_database(:name)
      index_keys(:name_keys, 'a', '4')
    end
    class Sequence < Model
      simulate_database 
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
end
