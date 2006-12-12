#!/usr/bin/env ruby
# Html::State::Drugs::Products -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/util/sort'
require 'oddb/html/view/drugs/products'

module ODDB
  module Html
    module State
      module Drugs
class Products < Drugs::Global
  include Util::Sort
  DIRECT_EVENT = :products
  VIEW = View::Drugs::Products
  def init
    sort_by(:product)
    sort
  end
  def _products(query)
    if(@model.query == query)
      sort
    else
      super
    end
  end
  def intervals
    alpha, others = partitioned_keys(ODDB::Drugs::Product.name_keys(1))
    keys = alpha.collect { |key| key.upcase }
    keys.push('0-9') unless(others.empty?)
    keys
  end
  def sort_proc(key)
    case key
    when :atc
      Proc.new { |prod| (atc = prod.atc) && atc.code || '' }
    when :company
      Proc.new { |prod| 
        (multilingual = prod.send(key)) \
          && multilingual.name.send(@session.language) || '' }
    when :product
      Proc.new { |prod| prod.name.send(@session.language) || '' }
    end
  end
end
      end
    end
  end
end
