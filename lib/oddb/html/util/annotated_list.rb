#!/usr/bin/env ruby
# Html::Util::AnnotatedList -- de.oddb.org -- 06.12.2006 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
class AnnotatedList < Array
  attr_accessor :error, :query, :origin
  def sort_by(*args, &block)
    _delegate(super(*args, &block))
  end
  def [](*args, &block)
    _delegate(super(*args, &block))
  end
  private
  def _delegate(content)
    self.dup.clear.concat(content)
  end
end
    end
  end
end
