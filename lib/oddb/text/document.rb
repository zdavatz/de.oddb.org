#!/usr/bin/env ruby
# Text::Document -- de.oddb.org -- 26.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Document
      attr_accessor :source
      attr_reader :chapters, :previous_sources
      def initialize
        @chapters = []
        @previous_sources = []
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
      def previous_sources=(sources)
        @previous_sources.concat sources.flatten
        @previous_sources.compact!
        @previous_sources.uniq!
        @previous_sources.delete @source
        @previous_sources
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
