#!/usr/bin/env ruby
# Model -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

class Object
  def metaclass; class << self; self; end; end
  def meta_eval &blk; metaclass.instance_eval &blk; end
end
module ODDB
  class Model
    class << self
      def simulate_database(*names)
        meta_eval {
          define_method(:instances) {
            @instances ||= []
          }
          define_method(:find_by_code) { |criteria|
            thing = instances.find { |instance| instance.codes.any? { |code| 
              code == criteria } }
          }
          names.each { |name|
            define_method("find_by_#{name}") { |nme|
              instances.find { |instance| instance.send(name) == nme }
            }
            define_method("search_by_#{name}") { |nme|
              instances.select { |instance| 
                /^#{nme}/i.match(instance.send(name).to_s)
              }
            }
          }
        }
        define_method(:save) {
          self.class.instances.push(self).uniq!
        }
      end
    end
  end
end
