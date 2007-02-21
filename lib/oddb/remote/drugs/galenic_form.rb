#!/usr/bin/env ruby
# Remote::Drugs::GalenicForm -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/util/multilingual'
require 'oddb/remote/object'

module ODDB
  module Remote
    module Drugs
class GalenicForm < Remote::Object
  def description
    @description ||= Util::Multilingual.new(:de => @remote.de)
  end
  def groupname
    @remote.galenic_group.de
  end
end
    end
  end
end
