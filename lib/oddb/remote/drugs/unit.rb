#!/usr/bin/env ruby
# Remote::Drugs::Unit -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/remote/object'
require 'oddb/util/multilingual'

module ODDB 
  module Remote
    module Drugs
class Unit < Remote::Object
  attr_reader :name
  def initialize(source, name)
    @name = Util::Multilingual.new(:de => name)
    super
  end
end
    end
  end
end

