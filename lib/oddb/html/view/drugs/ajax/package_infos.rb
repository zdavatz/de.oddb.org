#!/usr/bin/env ruby
# Html::View::Drugs::Ajax::PackageInfos -- de.oddb.org -- 07.03.2007 -- hwyss@ywesee.com

require 'htmlgrid/composite'
require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module View
      module Drugs
        module Ajax
class PackageInfos < HtmlGrid::Composite
  include PackageMethods
  LABELS = true
  LEGACY_INTERFACE = false
  COMPONENTS = {
    [0,0]   => :code_festbetragsgruppe,
    [0,1,0] => :code_festbetragsstufe,
    [1,1,0] => :opener_festbetragsstufe,
    [1,1,1] => :info_festbetragsstufe,
    [0,2,0] => :code_zuzahlungsbefreit,
    [1,2,0] => :opener_zuzahlungsbefreit,
    [1,2,1] => :info_zuzahlungsbefreit,
    [0,3]   => :code_prescription,
  }
  CSS_MAP = {
    [0,1,1,2] => 'top',
  }
  def code_festbetragsgruppe(model)
    if(code = super)
      link_festbetrag(code)
    end
  end
  def code_festbetragsstufe(model)
    if(code = super)
      link_festbetrag(sprintf("%s: %s", code, 
                      @lookandfeel.lookup("festbetragsstufe_#{code}")))
    end
  end
  def code_prescription(model)
    value = HtmlGrid::Value.new(:prescription, model, @session, self) 
    value.value = super
    value
  end
  def code_zuzahlungsbefreit(model)
    link = link_zuzahlungsbefreit(model)
    link.value = super
    link.label = true
    link
  end
  def info_festbetragsstufe(model)
    source = link_festbetrag('')
    source.value = source.href
    txt = @lookandfeel.lookup(:tt_code_festbetragsstufe).strip
    hidden = HtmlGrid::Div.new(model, @session, self)
    hidden.value = [ txt, source ]
    hidden.set_attribute('style', 'display:none')
    hidden.css_id = "info_festbetragsstufe#{model.code(:cid)}"
    hidden.css_class = "hidden"
    hidden
  end
  def info_zuzahlungsbefreit(model)
    source = link_zuzahlungsbefreit(model)
    source.value = source.href
    txt = @lookandfeel.lookup(:tt_code_zuzahlungsbefreit).strip
    hidden = HtmlGrid::Div.new(model, @session, self)
    hidden.value = [ txt, source ]
    hidden.set_attribute('style', 'display:none')
    hidden.css_id = "info_zuzahlungsbefreit#{model.code(:cid)}"
    hidden.css_class = "hidden"
    hidden
  end
  def link_festbetrag(code)
    link = HtmlGrid::Link.new(:festbetrag, model, @session, self)
    link.value = code
    link.href = "http://www.die-gesundheitsreform.de/glossar/festbetraege.html"
    link.label = true
    link
  end
  def link_zuzahlungsbefreit(model)
    link = HtmlGrid::Link.new(:zuzahlungsbefreit, model, @session, self)
    link.href = "http://www.bkk.de/bkk/powerslave,id,1081,nodeid,.html"
    link
  end
  def opener(code, type)
    span = HtmlGrid::Span.new(nil, @session, self)
    span.value = @lookandfeel.lookup(:more)
    widget = "package_infos#{code}_widget"
    hidden = "info_#{type}#{code}"
    span.onclick = "open_explanation('#{widget}', '#{hidden}', this)"
    span.css_class = 'opener'
    span
  end
  def opener_festbetragsstufe(model)
    opener(@model.code(:cid), :festbetragsstufe)
  end
  def opener_zuzahlungsbefreit(model)
    opener(@model.code(:cid), :zuzahlungsbefreit)
  end
end
        end
      end
    end
  end
end
