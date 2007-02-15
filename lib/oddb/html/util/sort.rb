#!/usr/bin/env ruby
# Html::Util::Sort -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
module Sort
  def sort
    if(key = @session.user_input(:sortvalue))
      sort_by(key.to_sym)
    end
    self
  end
  def sort_by(key)
    sorter = sort_proc(key) || Proc.new { |pac| pac.send(key) || '' }
    @model = @model.sort_by(&sorter)
    if(@sortvalue == key)
      @reverse = !@reverse
      if(@reverse)
        @model.reverse!
      end
    else
      @reverse = false
      @sortvalue = key
    end
  end
  def sort_proc(key)
  end
end
module PackageSort
  include Sort
  def sort_proc(key)
    case key
    when :atc
      Proc.new { |pac| (atc = pac.atc) && atc.code || '' }
    when :code_festbetragsstufe, :code_zuzahlungsbefreit
      Proc.new { |pac| 
        (code = pac.code(key)) && code.value || '' }
    when :company, :product
      Proc.new { |pac| 
        (multilingual = pac.send(key)) \
          && multilingual.name.send(@session.language) || '' }
    when :festbetrag, :price_public
      nilval = ODDB::Util::Money.new(0)
      Proc.new { |pac| pac.price(key) || nilval }
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
