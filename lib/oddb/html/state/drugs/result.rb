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
  include Util::Sort
  VIEW = View::Drugs::Result
  def init
    sort_by(:price_public)
    sort_by(:size)
    sort_by(:doses)
    sort_by(:product)
  end
  def direct_event
    [:search, :query, @model.query]
  end
  def _search(query)
    if(@model.query == query)
      self
    else
      super
    end
  end
  def sort_proc(key)
    case key
    when :atc
      Proc.new { |pac| (atc = pac.atc) && atc.code || '' }
    when :company, :product
      Proc.new { |pac| 
        (multilingual = pac.send(key)) \
          && multilingual.name.send(@session.language) || '' }
    when :festbetrag, :price_public
      nilval = ODDB::Util::Money.new(0)
      Proc.new { |pac| pac.price(key) || nilval }
    when :festbetragsstufe, :zuzahlungsbefreit
      Proc.new { |pac| 
        (code = pac.code(key)) && code.value || '' }
    when :price_difference
      nilval = ODDB::Util::Money.new(-9999999)
      Proc.new { |pac| 
        ((pf = pac.price(:festbetrag)) \
         && (pp = pac.price(:public)) \
         && pp - pf) || nilval
      }
    end
  end
end
      end
    end
  end
end
