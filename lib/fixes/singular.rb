#!/usr/bin/env ruby
# Fix for String#singular -- de.oddb.org -- 20.11.2006 -- hwyss@ywesee.com

require 'rubygems'
require 'facet/string/singular'

class String
  inflection_rule '', 'e', 'es'
end
