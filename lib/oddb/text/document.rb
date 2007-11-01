#!/usr/bin/env ruby
# Text::Document -- de.oddb.org -- 26.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Document
      attr_reader :chapters
      def initialize
        @chapters = []
      end
      def chapter(idx_or_name)
        case idx_or_name
        when Integer
          @chapters[idx_or_name]
        else
          @chapters.find { |ch| ch.name == idx_or_name }
        end
      end
      def add_chapter(chapter)
        @chapters.push chapter
      end
      def to_s
        @chapters.join("\n")
      end
    end
  end
end
