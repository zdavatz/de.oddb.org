require 'encoding/character/utf-8'
require 'iconv'

module ODDB
  module Import
    class Importer
      @@iconv = Iconv.new('utf8//IGNORE//TRANSLIT', 'latin1')
      @@lower = /^(and|for|in(cl)?|on|plain|with)$/i
      attr_accessor :report
      def initialize
        @report = []
        @skip_rows = 1
      end
      def capitalize_all(str)
        ## benchmarked fastest against an append (<<) solution
        str.split(/\b/).collect { |part|
          @@lower.match(part) ? part.downcase : part.capitalize }.join
      end
      def company_name(cname)
        cname = capitalize_all(cname.to_s)
        cname.gsub!(/\.(?!\s)/, '. ')
        cname.gsub!(/[\/&]/) { |match| ' %s ' % match }
        cname.gsub!(/Gmbh/, 'GmbH')
        cname.gsub!(/Ag\b/, 'AG')
        cname.gsub!(/\bKg\b/, 'KG')
        cname.strip!
        u(cname)
      end
      def postprocess
      end
      def utf8(str)
        u @@iconv.iconv(str) if str
      end
    end
  end
end
