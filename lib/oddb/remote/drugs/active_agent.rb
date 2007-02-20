#!/usr/bin/env ruby
# Remote::Drugs::ActiveAgent -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/remote/object'
require 'oddb/remote/drugs/substance'

module ODDB
  module Remote
    module Drugs
class ActiveAgent < Remote::Object
  def dose
    @dose ||= @remote.dose
  end
  def substance
    @substance ||= Remote::Drugs::Substance.new(@source, @remote.substance)
  end
  def <=>(other)
    if(dose.nil?)
      substance <=> other.substance
    else
      [substance, dose] <=> [other.substance, other.dose]
    end
  end
end
    end
  end
end
