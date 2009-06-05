#!/usr/bin/env ruby
# Html::Util::Sort -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
module Sort
  def sort
    _sort
    self
  end
  def _sort
    if(key = @session.user_input(:sortvalue))
      sort_by(key.to_sym)
    end
  end
  def sort_by(key, default='')
    sorter = sort_proc(key) || Proc.new { |pac| pac.send(key) || default }
    if(@sortvalue == key)
      @reverse = !@reverse
    else
      @reverse = false
      @sortvalue = key
    end
    @model = _sort_by(@model, @reverse, &sorter)
  end
  def _sort_by(model, reverse, &sorter)
    model = model.sort_by(&sorter)
    if(reverse)
      model.reverse!
    end
    model
  end
  def sort_proc(key)
  end
end
module PackageSort
  include Sort
  def sort_proc(key)
    case key
    when :company
      Proc.new { |pac| 
        (multilingual = pac.send(key)) \
          && multilingual.name.send(@session.language) || '' }
    when :ddd_prices
      Proc.new { |pac| 
        pac.ddds.collect { |ddd| pac.dose_price(ddd.dose) }.compact
      }
    when :difference
      nilval = 9999999.0
      Proc.new { |pac| pac.difference || nilval }
    when :package_infos
      Proc.new { |pac| [ 
        pac.code(:festbetragsgruppe).to_s,
        pac.code(:festbetragsstufe).to_s,
        pac.code(:prescription).to_s, 
        pac.code(:zuzahlunggsbefreit).to_s,
      ] }
    when :price_public, :price_festbetrag
      nilval = ODDB::Util::Money.new(0)
      key = key.to_s.sub(/^price_/, '').to_sym
      Proc.new { |pac| pac.price(key) || nilval }
    when :product
      Proc.new { |pac| 
        pac.name.send(@session.language) \
          || ((prod = pac.product) && prod.name.send(@session.language)) || '' }
    end
  end
end
    end
  end
end
