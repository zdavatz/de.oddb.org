#!/usr/bin/env ruby
# Text::Document -- de.oddb.org -- 11.03.2008 -- hwyss@ywesee.com

module ODDB
  module Text
    class Document < Model
      odba_index :source
      serialize :chapters
    end
  end
end
