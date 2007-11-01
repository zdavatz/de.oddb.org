#!/usr/bin/env ruby
# Fix for Yaml -- de.oddb.org -- 01.11.2007 -- hwyss@ywesee.com

require 'yaml'

## FIXME: the following works around Character::Encoding::UTF8 hanging when 
#         yaml's String#is_binary_data? calls self.count("\x00")
class String
  def is_binary_data?
    ( self.count( "^ -~", "^\r\n" ) / self.size > 0.3 \
     || self.include?( "\x00" ) ) unless empty?
  end
end
