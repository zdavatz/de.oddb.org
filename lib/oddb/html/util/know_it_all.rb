#!/usr/bin/env ruby
# KnowItAll -- de.oddb.org -- 15.01.2009 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
class KnowItAll
  def initialize delegate, values={}
    @delegate = delegate
    @values = values
  end
  def is_a? mod
    @delegate.is_a?(mod) || super
  end
  def method_missing name, *args, &block
    if @delegate.respond_to? name
      @delegate.send name, *args, &block
    else
      @values[name]
    end
  end
end
    end
  end
end
