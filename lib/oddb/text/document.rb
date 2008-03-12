#!/usr/bin/env ruby
# Text::Document -- de.oddb.org -- 26.10.2007 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Text
    ## to migrate Document to be a subclass of Model:
    #  Drugs::Sequence.all { |seq| need = false; [:fachinfo, :patinfo].each { |key| if(ml = seq.instance_variable_get("@#{key}")); need = true; seq.instance_variable_set("@#{key}", nil); if(doc = ml.de); info = seq.send(key); if(prev = doc.instance_variable_get('@previous_sources')); info.previous_sources[:de] = prev; doc.instance_eval { remove_instance_variable('@previous_sources') }; end; if((source = doc.source) && (saved = Text::Document.find_by_source(source))); doc = saved; end; info.de = doc; info.save; info.de.save; end; end }; seq.save if need }
    class Document < Model
      attr_accessor :source, :date
      attr_reader :chapters
      def initialize
        @chapters = []
      end
      def add_chapter(chapter)
        @chapters.push chapter
      end
      def chapter(idx_or_name)
        case idx_or_name
        when Integer
          @chapters[idx_or_name]
        else
          @chapters.find { |ch| ch.name == idx_or_name }
        end
      end
      def chapter_names
        @chapters.select { |chapter| 
          chapter.paragraphs.size > 1 
        }.collect { |chapter| 
          chapter.name 
        }
      end
      def remove_chapter(chapter)
        @chapters.delete(chapter)
      end
      def to_s
        @chapters.join("\n")
      end
    end
  end
end
