#!/usr/bin/env ruby
# Remote::Drugs::Atc -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/remote/object'
require 'oddb/util/multilingual'

module ODDB
  module Remote
    module Drugs
class Atc < Remote::Object
  delegate :code
  def name
    @name ||= Util::Multilingual.new(:de => @remote.name)
  end
end
    end
  end
end
