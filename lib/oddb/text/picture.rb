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
      def digest
        @digest ||= Digest::MD5.hexdigest(self)
      end
      def empty?
        super #|| !image
      rescue StandardError => err
        puts err.class
        puts err.message
        true
      end
      def finalize!
        wmf = File.join ODDB.config.var, path("%s.wmf" % digest)
        FileUtils.mkdir_p File.dirname(wmf)
        File.open(wmf, 'w') { |fh| fh.puts blob }
        img = Magick::Image.read(wmf) { 
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
        path = File.join ODDB.config.var, path("%s.png" % digest)
        File.open(path, 'w') { |fh| fh.puts to_png }
      end
      def filename
        @filename ||= "%s.png" % digest
      end
      def image
        Magick::Image.from_blob(blob).first
      end
      def path(fn = filename)
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
