#!/usr/bin/env ruby
# Import::Xml -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'rexml/document'

module ODDB
  module Import
    class Xml
      def import(io)
        import_document(REXML::Document.new(io))
      end
    end
  end
end
