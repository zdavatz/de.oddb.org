#!/usr/bin/env ruby
# Text::Paragraph -- de.oddb.org -- 19.10.2007 -- hwyss@ywesee.com

require 'delegate'
require 'encoding/character/utf-8'
require 'oddb/text/format'

module ODDB
  module Text
    class Paragraph < DelegateClass(String)
      attr_reader :text, :formats
      def initialize(str='')
        @formats = []
        @text = u(str.dup)
				set_format()
        super(@text)
      end
      def set_format(*args)
        if(fmt = @formats.last)
          return if(fmt == args)
          if(fmt.start == @text.length)
            @formats.pop
            fmt = @formats.last
            if(fmt == args)
              fmt.end = -1
              return
            end
          else
            fmt.end	= (@text.length - 1)
          end
        end
        fmt = Text::Format.new(*args)
        fmt.start = (@text.length)
        @formats.push(fmt)
        fmt
      end
      def <<(str)
        if(str.is_a? Paragraph)
          txt = str.text
          str.formats.each { |fmt|
            set_format(*fmt.values)
            @text << txt[fmt.range]
          }
        else
          @text << str
        end
        self
      end
    end
  end
end
