#!/usr/bin/env ruby
# Import::TestRtf -- de.oddb.org -- 16.10.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/import/rtf'

module ODDB
  module Import
    class TestRtf < Test::Unit::TestCase
      def setup
        @importer = Rtf.new
      end
      def test_import__rtf
        path = File.expand_path('data/rtf/pharmnet/selegilin.rtf', 
                                File.dirname(__FILE__))
        document = nil
        File.open(path) { |fh|
          document = @importer.import(fh)
        }
        assert_instance_of(Text::Document, document)
        assert_equal(1, document.chapters.size)
        assert_instance_of(Text::Chapter, document.chapter('default'))
      end
      def test_import__html__raises_error
        path = File.expand_path('data/html/pharmnet/Gate.html', 
                                File.dirname(__FILE__))
        assert_raises(ArgumentError) do
          File.open(path) do |fh|
            @importer.import(fh)
          end
        end
      end
    end
  end
end
