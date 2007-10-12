#!/usr/bin/env ruby
# Export::Yaml -- de.oddb.org -- 09.10.2007 -- hwyss@ywesee.com

require 'yaml'
require 'oddb/business/company'
require 'oddb/drugs'

## FIXME: the following works around Character::Encoding::UTF8 hanging when 
#         yaml's String#is_binary_data? calls self.count("\x00")
class String
  def is_binary_data?
    ( self.count( "^ -~", "^\r\n" ) / self.size > 0.3 \
     || self.include?( "\x00" ) ) unless empty?
  end
end
module ODDB
  module OddbUri
    YAML_URI = '!de.oddb.org,2007'
    yaml_as YAML_URI
		def to_yaml_type
			"#{YAML_URI}/#{self.class}"
		end
    def to_yaml( opts = {} )
      YAML::quick_emit( self.object_id, opts ) { |out|
        out.map( taguri ) { |map|
          to_yaml_map(map)
        }
      }
    end
    def to_yaml_map(map)
      if(respond_to?(:oid) && id = oid)
        map.add("oid", id) 
      end
      to_yaml_properties.each { |m|
        map.add( m[1..-1], instance_variable_get( m ) )
      }
    end
  end
  module Yaml
    include OddbUri
    def to_yaml_properties
      super - self.class.connections - self.class.connectors
    end
    def Yaml.append_features(mod)
      super
      mod.module_eval {
        class << self 
          def export(*args)
            define_method(:to_yaml_properties) {
              super.push(*args).reject { |name| 
                instance_variable_get(name).nil? }
            }
          end
        end
      }
    end
  end
  class Model
    include Yaml
  end
  module Util
    class Code
      include OddbUri 
      def to_yaml_map(map)
        super
        map.add('value', value)
      end
      def to_yaml_properties
        super - ['@values']
      end
    end
    class Multilingual
      include OddbUri
    end
  end
  module Drugs
    class ActiveAgent
      export '@substance'
    end
    class Atc
      export '@ddds'
    end
    class Composition
      export '@active_agents', '@parts'
    end
    class Dose
      include OddbUri
      def to_yaml_properties
        [ '@val', '@unit' ]
      end
    end
    class GalenicForm
      export '@group'
    end
    class Package
      def to_yaml_map(map)
        super
        map.add('prices', self.prices.inject({}) { |memo, price|
          memo.store(price.type, price.to_f)
          memo 
        } )
      end
      def to_yaml_properties
        (super - ['@prices']).push('@parts')
      end
    end
    class Product
      export '@company', '@sequences'
    end
    class Sequence
      export '@atc', '@compositions', '@packages'
    end
    class Substance
      export '@group'
    end
  end
  module Export
    module Yaml
class Drugs
  def export(io)
    ODDB::Drugs::Product.all { |product| io.puts product.to_yaml }
  end
end
    end
  end
end
