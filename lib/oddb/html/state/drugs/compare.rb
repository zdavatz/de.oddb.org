#!/usr/bin/env ruby
# Html::State::Drugs::Comparison -- de.oddb.org -- 14.02.2007 -- hwyss@ywesee.com

require 'delegate'
require 'oddb/html/state/global_predefine'
require 'oddb/html/util/sort'
require 'oddb/html/view/drugs/compare'

module ODDB
  module Html
    module State
      module Drugs
class Compare < Global
  include Util::PackageSort
  VIEW = View::Drugs::Compare
  class Comparison < SimpleDelegator
    attr_reader :difference
    def initialize(package, original)
      psize = package.size.to_f
      pprice = package.price(:public).to_f
      osize = original.size.to_f
      oprice = original.price(:public).to_f
      unless((psize * pprice * osize * oprice) == 0)
        @difference = ((osize * pprice) / (psize * oprice) - 1) * 100
      end
      super(package)
    end
  end
  def init
    original = @model.origin
    @model.collect! { |package| Comparison.new(package, original) }
    sort_by(:product)
    sort_by(:difference)
    sort
  end
  def _compare(code)
    if(code == @model.query)
      sort
    else
      super
    end
  end
  def direct_event
    direct_event = [:compare]
    if(code = @model.query)
      direct_event.push(code)
    end
    direct_event
  end
end
      end
    end
  end
end
