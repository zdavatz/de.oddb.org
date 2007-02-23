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
      self.class.connectors.each { |conn|
        self.send(conn).odba_delete
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
      self.class.connectors.each { |conn|
        self.send(conn).odba_store
      }
      self
    end
    class << self
      alias :all :odba_extent
      def serializables
        @serializables ||= []
      end
      def serialize(*keys)
        keys.each { |key|
          connectors.delete(key)
          serializables.push("@#{key}")
        }
      end
    end
  end
end
