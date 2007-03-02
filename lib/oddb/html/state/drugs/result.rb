#!/usr/bin/env ruby
# Html::State::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/util/sort'
require 'oddb/html/view/drugs/result'

module ODDB
  module Html
    module State
      module Drugs
class Result < Drugs::Global
  include Util::PackageSort
  VIEW = View::Drugs::Result
  def init
    partition!
    sort_by(:price_public)
    sort_by(:size)
    sort_by(:active_agents)
    sort_by(:product)
    sort
  end
  def direct_event
    [:search, :query, @model.query]
  end
  def partition!
    atcs = {}
    while(package = @model.shift)
      code = (atc = package.atc) ? atc.code : 'Z'
      (atcs[code] ||= Util::AnnotatedList.new(:atc => atc)).push(package)
    end
    atcs.sort.each { |code, array|
      @model.push(array)
    }
  end
  def _search(query)
    if(@model.query == query)
      sort
    else
      super
    end
  end
  def _sort_by(model, reverse, &sorter)
    model.collect! { |array|
      super(array, reverse, &sorter)
    }
  end
end
      end
    end
  end
end
