#!/usr/bin/env ruby
# Html::State::Drugs::Comparison -- de.oddb.org -- 14.02.2007 -- hwyss@ywesee.com

require 'oddb/util/comparison'
require 'oddb/html/state/global_predefine'
require 'oddb/html/util/sort'
require 'oddb/html/view/drugs/compare'

module ODDB
  module Html
    module State
      module Drugs
class Compare < Global
  include Util::PackageSort
  LIMIT = true
  VIEW = View::Drugs::Compare
  def init
    original = @model.origin
    @model.collect! { |package| 
      ODDB::Util::Comparison.new(package, original) }
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
      direct_event.push(:query, code)
    end
    direct_event
  end
end
class CompareRemote < Compare
  def direct_event
    direct_event = [:compare_remote]
    if((origin = @model.origin) && (uid = origin.uid))
      direct_event.push(:uid, uid)
    end
    direct_event
  end
end
      end
    end
  end
end
