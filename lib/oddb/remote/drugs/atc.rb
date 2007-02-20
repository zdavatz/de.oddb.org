#!/usr/bin/env ruby
# Remote::Drugs::Atc -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/remote/object'
require 'oddb/util/multilingual'

module ODDB
  module Remote
    module Drugs
class Atc < Remote::Object
  def code
    @code ||= @remote.code
  end
  def name
    @name ||= Util::Multilingual.new(:de => @remote.de)
  end
end
    end
  end
end
