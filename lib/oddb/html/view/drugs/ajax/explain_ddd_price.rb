#!/usr/bin/env ruby
# Html::View::Drugs::Ajax::ExplainDddPrice -- de.oddb.org -- 07.03.2007 -- hwyss@ywesee.com

require 'htmlgrid/composite'
require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module View
      module Drugs
        module Ajax
class ExplainDddPrice < HtmlGrid::Composite
  include View::Drugs::PackageMethods
  COMPONENTS = {
    [0,0] =>  :administration,
    [2,0] =>  :comment,
    [0,1]	=>	:ddd,
    [2,1]	=>	:price_public,
    [0,2]	=>	:dose,
    [2,2]	=>	:package_size,
    [0,3]	=>	:ddd_price_calculation,
  }
	COLSPAN_MAP = {
		[1,3]	=>	3,
	}
  CSS_MAP = {
    [0,0,4,4] => 'calculation',
  }
  LABELS = true
  LEGACY_INTERFACE = false
  class << self
    def data(*keys)
      keys.each { |key|
        define_method(key) { |model|
          value key, self.send("_#{key}", model)
        }
      }
    end
  end
  data :comment, :ddd, :ddd_price, :dose, :price_public
  def administration(model)
    adm = model[:ddd].administration
    value(:administration, 
          @lookandfeel.lookup("administration_#{adm}") { adm })
  end
  def _comment(model)
    model[:ddd].comment
  end
  def _ddd(model)
    model[:ddd].dose
  end
  def _ddd_price(model)
    adjust_price model[:package].ddd_price(model[:ddd])
  end
  def ddd_price_calculation(model)
    comp = HtmlGrid::Value.new(:ddd_price_calculation, 
                               model, @session, self)
    comp.value = @lookandfeel.lookup(:ddd_price_calculation,
                                     _ddd(model), _dose(model), 
                                     _price_public(model), 
                                     _package_size(model), 
                                     _ddd_price(model))
    comp
  end
  def _dose(model)
    model[:package].doses.first
  end
  def _price_public(model)
    adjust_price model[:package].price(:public)
  end
  def package_size(model)
    value :size, _package_size(model)
  end
  def _package_size(model)
    size(model[:package])
  end
  def value(key, value)
    val = HtmlGrid::Value.new(key, @model, @session, self)
    val.value = value
    val
  end
end
        end
      end
    end
  end
end
