#!/usr/bin/env ruby
# Html::View::Drugs::Ajax::RemoteInfos -- de.oddb.org -- 07.03.2007 -- hwyss@ywesee.com

require 'htmlgrid/composite'

module ODDB
  module Html
    module View
      module Drugs
        module Ajax
class RemoteInfos < HtmlGrid::Composite
  LABELS = true
  LEGACY_INTERFACE = false
  COMPONENTS = {
    [0,0] => :ch_sl_entry,
    [0,1] => :ch_ikscat,
  }
  CSS_MAP = {
    [0,1] => 'top',
  }
  DEFAULT_CLASS = HtmlGrid::Value
  def ch_sl_entry(model)
    value = HtmlGrid::Value.new(:ch_sl_entry, model, @session, self)
    value.value = @lookandfeel.lookup(model.sl_entry ? :yes : :no)
    value
  end
  def ch_ikscat(model)
    value = HtmlGrid::Value.new(:ch_ikscat, model, @session, self)
    span = HtmlGrid::Span.new(model, @session, self)
    span.value = code = model.ikscat.to_s
    if(code =~ /[AB]/)
      span.css_class = 'prescription'
    else
      span.css_class = 'otc'
    end
    value.value = [span, ":", @lookandfeel.lookup("ch_ikscat_#{code}")]
    value
  end
end
        end
      end
    end
  end
end
