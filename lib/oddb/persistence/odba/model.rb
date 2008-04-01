#!/usr/bin/env ruby
# Model -- de.oddb.org -- 07.09.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  class Model
    include ODBA::Persistable
    unless(instance_methods.include?('__odba_delete__'))
      alias :__odba_delete__ :delete
    end
    def delete
      __odba_delete__
      self.class.connectors.each { |name|
        if(conn = instance_variable_get(name))
          conn.odba_delete
        end
      }
      odba_delete
    end
    def odba_serializables
      super.concat self.class.serializables
    end
    unless(instance_methods.include?('__odba_save__'))
      alias :__odba_save__ :save
    end
    def save
      __odba_save__
      odba_isolated_store
      self.class.connectors.each { |name|
        if((conn = instance_variable_get(name)) && conn.respond_to?(:odba_store))
          conn.odba_store
        end
      }
      self
    end
    class << self
      alias :all :odba_extent
      alias :count :odba_count
      def serializables
        @serializables ||= []
      end
      def serialize(*keys)
        keys.each { |key|
          name = "@#{key}"
          connectors.delete(name)
          serializables.push(name)
        }
      end
    end
    serialize :data_origins
  end
end
