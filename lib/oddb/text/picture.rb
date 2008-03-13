#!/usr/bin/env ruby
# Text::Picture -- de.oddb.org -- 24.10.2007 -- hwyss@ywesee.com

module ODDB
  module Text
    class Picture < DelegateClass(String)
      attr_accessor :height, :width, :xscale, :yscale, :height_goal, :width_goal
      TWIP = 20 ## see http://en.wikipedia.org/wiki/Twip
      PCNT = 100 
      BDNS = 180 ## base density
      DMAX = 360 ## maximum density
      def initialize
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
        ODDB.logger.error("Text::Picture") { 
          sprintf "%s: %s", err.class, err.message
        }
        true
      end
      def finalize!
        wmf = File.join ODDB.config.var, path("%s.wmf" % digest)
        FileUtils.mkdir_p File.dirname(wmf)
        File.open(wmf, 'w') { |fh| fh.puts blob }
        xdns = [DMAX, BDNS * _xscale / PCNT].min
        ydns = [DMAX, BDNS * _yscale / PCNT].min
        img = Magick::Image.read(wmf) { 
          self.density = "#{xdns}x#{ydns}"
        }.first
        twidth = (@width || img.columns) * _xscale / PCNT
        theight = (@height || img.rows) * _yscale / PCNT

        geom = sprintf("%ix%i!", twidth / TWIP, theight / TWIP)
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
      def _xscale
        if @xscale
          @xscale
        elsif @width && @width_goal
          PCNT * @width_goal / @width 
        else
          PCNT
        end
      end
      def _yscale
        if @yscale
          @yscale
        elsif @height && @height_goal
          PCNT * @height_goal / @height 
        else
          PCNT
        end
      end
    end
  end
end
