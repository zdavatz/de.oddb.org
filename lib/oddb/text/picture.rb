#!/usr/bin/env ruby
# Text::Picture -- de.oddb.org -- 24.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Picture < DelegateClass(String)
      attr_accessor :height, :width, :xscale, :yscale
      TWIP = 20 ## see http://en.wikipedia.org/wiki/Twip
      PCNT = 100 
      def initialize
        @xscale = @yscale = 100
        super('')
      end
      def blob
        [self].pack('H*')
      end
      def empty?
        super || !image
      rescue
        true
      end
      def finalize!
        img = Magick::Image.from_blob(blob) { 
          self.density = "720x720"
        }.first
        geom = sprintf("%ix%i!", 
                       (@width || img.columns) / TWIP * @xscale / PCNT, 
                       (@height || img.rows) / TWIP * @yscale / PCNT)
        img.change_geometry(geom) { |cols, rows, tmp|
          img.resize!(cols, rows)
        }
        png = img.to_blob { 
          self.format = 'PNG' 
        }
        replace png.unpack('H*').first
      end
      def filename
        @filename ||= "%s.png" % Digest::MD5.hexdigest(self)
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
        blob
      end
      def to_s
        image.inspect
      end
    end
  end
end
