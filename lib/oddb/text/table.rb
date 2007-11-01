#!/usr/bin/env ruby
# Text::Table -- de.oddb.org -- 19.10.2007 -- hwyss@ywesee.com

require 'oddb/text/paragraph'

module ODDB
  module Text
    class Table
      def initialize(*args)
        super
        @rows = [[]]
        next_cell!
      end
      def clean!
        @rows.each { |row|
          while((cell = row.last) && cell.empty?)
            row.pop
          end
        }
        while((row = @rows.last) && row.empty?)
          @rows.pop
        end
      end
      def column_widths
        @rows.inject([]) { |memo, row|
          row.each_with_index { |cell, idx|
            memo[idx] = [memo[idx].to_i, cell.length].max
          }
          memo
        }
      end
      def empty?
        @rows.flatten.all? { |cell| cell.strip.empty? }
      end
      def next_cell!
        cell = Paragraph.new
        @rows.last.push cell
        cell
      end
      def next_row!
        @rows.push []
        next_cell!
      end
      def each_normalized(&block)
        wd = width
        @rows.each { |row|
          block.call(row + Array.new(wd - row.length))
        }
      end
      def to_s
        widths = column_widths
        @rows.collect { |row|
          line = ''
          row.each_with_index { |cell, idx|
            line << cell.to_s.ljust(widths.at(idx) + 2)
          }
          line
        }.join("\n")
      end
      def width
        @rows.collect { |row| row.length }.max  
      end
      def <<(str)
        @rows.last.last << str
      end
    end
  end
end
