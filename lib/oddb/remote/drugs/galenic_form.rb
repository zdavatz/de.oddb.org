#!/usr/bin/env ruby
# Remote::Drugs::GalenicForm -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/util/multilingual'
require 'oddb/remote/object'
require 'oddb/drugs/galenic_group'

module ODDB
  module Remote
    module Drugs
class GalenicForm < Remote::Object
  def description
    @description ||= Util::Multilingual.new(:de => @@iconv.iconv(@remote.de))
  end
  def group
    @group ||= ODDB::Drugs::GalenicGroup.find_by_name(groupname)
  end
  def groupname
    @groupname ||= @remote && @@iconv.iconv(@remote.galenic_group.de)
  end
end
    end
  end
end
