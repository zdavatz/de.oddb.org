#!/usr/bin/env ruby
# Text::Picture -- de.oddb.org -- 24.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Picture < DelegateClass(String)
      attr_accessor :height, :width
      PNG_SCALE = 20 ## 1440 / 72
      def initialize(str='')
        @data = str.dup
        super(@data)
      end
      def blob
        [@data].pack('H*')
      end
      def filename
        @filename ||= "%s.png" % Digest::MD5.hexdigest(@data)
      end
      def formats
        []
      end
      def image
        Magick::Image.from_blob(blob).first
      end
      def path
        fn = filename
        File.join('/images', fn[0,2], fn)
      end
      def set_format(*ignore)
      end
      def to_png
        img = image
        geom = sprintf("%ix%i!", (@width || img.columns) / PNG_SCALE, 
                                 (@height || img.rows) / PNG_SCALE)
        img.change_geometry(geom) { |cols, rows, tmp|
          img.resize!(cols, rows)
        }
        img.to_blob { 
          self.format = 'PNG' 
        }
      end
      def to_s
        image.inspect
      end
    end
  end
end
