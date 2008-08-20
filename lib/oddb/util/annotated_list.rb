#!/usr/bin/env ruby
# Util::AnnotatedList -- de.oddb.org -- 06.12.2006 -- hwyss@ywesee.com

module ODDB
  module Util
class AnnotatedList < Array
  def initialize(annotations = {})
    if(annotations.is_a?(Hash))
      super()
      @annotations = annotations
    else
      super
      @annotations = {}
    end
  end
  def sort_by(*args, &block)
    _delegate(super(*args, &block))
  end
  def [](*args, &block)
    _delegate(super(*args, &block))
  end
  def method_missing(key, *args)
    mname = key.id2name
    if(args.size == 1 && /=$/.match(mname))
      mname.chop!
      @annotations[mname.to_sym] = args.first
    else
      @annotations[key]
    end
  end
  private
  def _delegate(content)
    self.dup.clear.concat(content)
  end
end
  end
end
