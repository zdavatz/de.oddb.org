#!/usr/bin/env ruby
# Remote::Drugs::Atc -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/remote/object'
require 'oddb/util/multilingual'

module ODDB
  module Remote
    module Drugs
class Atc < Remote::Object
  delegate :code, :parent_code
  def initialize *args
    super
    @ddds = {}
  end
  def name
    @name ||= Util::Multilingual.new(:de => @remote.name)
  end
  def ddds(administration)
    @ddds[administration] ||= @remote.ddds.inject([]) { |memo, (roa, ddd)| 
      memo.push ddd if roa == administration 
      memo
    }
  end
  def interesting?
    false
  end
end
    end
  end
end
