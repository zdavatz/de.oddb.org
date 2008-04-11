#!/usr/bin/env ruby
# Html::Util::UnsavedHelper -- de.oddb.org -- 10.04.2008 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
class UnsavedHelper
  attr_reader :delegate
  def initialize(delegate)
    @delegate = delegate
  end
  def method_missing(key, *args, &block)
    unless /^(add_|save$)/.match(key.to_s)
      @delegate.send(key, *args, &block)
    end
  end
end
    end
  end
end
