#!/usr/bin/env ruby
# Html::Util::AnnotatedList -- de.oddb.org -- 06.12.2006 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
class AnnotatedList < Array
  attr_accessor :error, :query
  def sort_by(*args, &block)
    self.dup.clear.concat(super(*args, &block))
  end
end
    end
  end
end
