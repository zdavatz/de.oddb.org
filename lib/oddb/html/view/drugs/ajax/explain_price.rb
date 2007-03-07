#!/usr/bin/env ruby
# Html::View::Drugs::Ajax::ExplainPrice -- de.oddb.org -- 07.03.2007 -- hwyss@ywesee.com

require 'htmlgrid/composite'

module ODDB
  module Html
    module View
      module Drugs
        module Ajax
class ExplainPrice < HtmlGrid::Composite
  COMPONENTS = {
    [0,0] => :price_db,
    [0,1] => :tax_sub,
    [0,2] => :tax_add,
    [0,3] => :price_local,
  }
  CSS_MAP = {
    [1,0,1,3] => 'price',
    [0,3]     => 'sum',
    [1,3]     => 'price sum',
  }
  LABELS = true
  LEGACY_INTERFACE = false
  def price_local(price)
    _value :price_local, _price_local(price)
  end
  def _price_local(price)
    price * @lookandfeel.price_factor
  end
  def price_db(price)
    _value :price_db, _price_db(price)
  end
  def _price_db(price)
    price * @lookandfeel.currency_factor
  end
  def tax_add(price)
    _value :tax_add, ['+', _tax_add(price)]
  end
  def _tax_add(price)
    factor = @lookandfeel.tax_factor_add
    _price_local(price) / (1.0 + factor) * factor
  end
  def tax_sub(price)
    _value :tax_sub, ['-', _tax_sub(price)]
  end
  def _tax_sub(price)
    factor = @lookandfeel.tax_factor_sub
    _price_db(price) / (1.0 + factor) * factor
  end
  def _value(key, price)
    value = HtmlGrid::Value.new(key, price, @session, self)
    value.value = price
    value
  end
end
        end
      end
    end
  end
end
