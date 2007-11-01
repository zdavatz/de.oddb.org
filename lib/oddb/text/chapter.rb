#!/usr/bin/env ruby
# Text::Chapter -- de.oddb.org -- 24.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Chapter
      attr_reader :name, :paragraphs
      def initialize(name)
        @name = name
        @paragraphs = []
      end
      def add_paragraph(paragraph)
        @paragraphs.push paragraph unless paragraph.empty?
      end
      def to_s
        @paragraphs.join("\n")
      end
    end
  end
end
