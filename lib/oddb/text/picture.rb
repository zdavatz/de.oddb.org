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

        twidth = @width ? @width * _xscale / PCNT : @width_goal
        theight = @height ? @height * _yscale / PCNT : @height_goal

        geom = sprintf("%ix%i!", twidth / TWIP, theight / TWIP)
        path = File.join ODDB.config.var, path("%s.png" % digest)
        
        # let imagemagick take care of file-conversion externally
        out = %x{convert -resize #{geom} #{wmf} #{path}}
        if $? != 0
          raise out
        end

        png = File.read path
        replace png.unpack('H*').first
      end
      def filename
        @filename ||= "%s.png" % digest
      end
      def formats
        []
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
