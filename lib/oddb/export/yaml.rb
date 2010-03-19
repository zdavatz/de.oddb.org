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
class Infos
  def export(io)
    raise "please specify which type of document you want to export" unless infotype
    infos = []
    ## Documents may be garbage-collected during this export. That's why we'll
    #  keep names in a separate table on the stack, and assign them just before
    #  calling #to_yaml
    names = {}
    ODDB::Drugs::Sequence.all do |seq|
      info = seq.send infotype
      # export sequence names as title
      unless info.empty?
        lnms = names[info.oid] ||= {}
        info.canonical.each do |key, doc|
          if (doc = info.send(key)) && (name = identify_name(seq, key))
            lnms[key] = name
          end
        end
        infos.push info
      end
    end
    infos.uniq!
    infos.each do |info|
      info.canonical.each do |key, doc|
        doc.title = names[info.oid][key]
      end
      io.puts info.to_yaml
    end
    nil
  end
end
class Fachinfos < Infos
  def infotype
    :fachinfo
  end
  def identify_name seq, lang
    seq.cascading_name(lang)
  end
end
class Patinfos < Infos
  def infotype
    :patinfo
  end
  def identify_name seq, lang
    names = seq.packages.collect do |pac| u pac.cascading_name(lang) end.uniq
    if names.size == 1
      return names.first
    end
    name = ''
    pos = 0
    while(chars = names.collect do |nm| nm[pos,1] end.uniq; chars.size == 1) do
      pos += 1
      name << chars.first
    end 
    name.gsub! /\([^\)]+$/u, ''
    name.strip
  end
end
    end
  end
end
