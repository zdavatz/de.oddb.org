#!/usr/bin/env ruby
# Html::State::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/result'

module ODDB
  module Html
    module State
      module Drugs
class Result < Drugs::Global
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
  def sort
    sort_by(@session.user_input(:sortvalue).to_sym)
    self
  end
  def sort_by(key)
    sorter = case key
             when :atc
               Proc.new { |pac| (atc = pac.atc) && atc.code }
             when :company, :product
               Proc.new { |pac| 
                 (multilingual = pac.send(key)) \
                   && multilingual.name.send(@session.language) }
             when :festbetrag, :price_public
               Proc.new { |pac| 
                 (price = pac.price(key)) && price.value }
             when :festbetragsstufe, :zuzahlungsbefreit
               Proc.new { |pac| (code = pac.code(key)) && code.value }
             else
               Proc.new { |pac| pac.send(key) }
             end
    @model.packages = @model.packages.sort_by(&sorter)
    if(@sortvalue == key)
      @reverse = !@reverse
      if(@reverse)
        @model.packages.reverse!
      end
    else
      @reverse = false
      @sortvalue = key
    end
  end
end
      end
    end
  end
end
