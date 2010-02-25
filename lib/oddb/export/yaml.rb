#!/usr/bin/env ruby
# Export::Yaml -- de.oddb.org -- 09.10.2007 -- hwyss@ywesee.com

require 'fixes/yaml'
require 'oddb/business/company'
require 'oddb/drugs'

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
              super.push(*args).uniq.reject { |name| 
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
    class M10lDocument
      export '@canonical'
    end
  end
  module Business
    class Company
      export '@name'
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
  module Text
    class Document
      export '@title', '@chapters', '@date', '@source'
    end
    class Chapter
      include OddbUri
    end
    class Paragraph
      include OddbUri
      def to_yaml_properties
        [ '@text', '@formats' ]
      end
    end
    class Picture
      include OddbUri
      def to_yaml_map(map)
        super
        map.add('path', path)
      end
    end
    class Table
      include OddbUri
    end
    class Format
      include OddbUri
    end
  end
  module Export
    module Yaml
class Drugs
  def export(io)
    ODDB::Drugs::Product.all { |product| io.puts product.to_yaml }
    nil
  end
end
class Fachinfos
  def export(io)
    fachinfos = []
    ## Documents may be garbage-collected during this export. That's why we'll
    #  keep names in a separate table on the stack, and assign them just before
    #  calling #to_yaml
    names = {}
    ODDB::Drugs::Sequence.all do |seq|
      fachinfo = seq.fachinfo
      # export sequence names as title
      unless fachinfo.empty?
        lnms = names[fachinfo.oid] ||= {}
        fachinfo.canonical.each do |key, doc|
          if (doc = fachinfo.send(key)) && (name = seq.cascading_name(key))
            lnms[key] = name
          end
        end
        fachinfos.push fachinfo
      end
    end
    fachinfos.uniq!
    fachinfos.each do |fachinfo|
      fachinfo.canonical.each do |key, doc|
        doc.title = names[fachinfo.oid][key]
      end
      io.puts fachinfo.to_yaml
    end
    nil
  end
end
    end
  end
end
