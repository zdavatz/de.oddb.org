#!/usr/bin/env ruby
# Remote::Drugs::Substance -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/remote/object'
require 'oddb/util/multilingual'

module ODDB
  module Remote
    module Drugs
class Substance < Remote::Object
  def name
    @name ||= Util::Multilingual.new(:de => @@iconv.iconv(@remote.de))
  end
  def <=>(other)
    @name <=> other.name
  end
end
    end
  end
end
