#!/usr/bin/env ruby
# Html::View::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/div'
require 'htmlgrid/span'
require 'oddb/html/view/google'
require 'oddb/html/view/list'
require 'oddb/html/view/search'
require 'oddb/html/view/drugs/legend'
require 'oddb/html/view/drugs/package'
require 'oddb/html/view/drugs/products'
require 'oddb/html/view/drugs/template'

module ODDB
  module Html
    module View
      module Drugs
class PackageInfos < HtmlGrid::Composite
  include PackageMethods
  LABELS = true
  LEGACY_INTERFACE = false
  COMPONENTS = {
    [0,0]   => :price_difference,
    [0,1]   => :code_festbetragsgruppe,
    [0,2,0] => :code_festbetragsstufe,
    [1,2,0] => :opener_festbetragsstufe,
    [1,2,1] => :info_festbetragsstufe,
    [0,3,0] => :code_zuzahlungsbefreit,
    [1,3,0] => :opener_zuzahlungsbefreit,
    [1,3,1] => :info_zuzahlungsbefreit,
    [0,4]   => :code_prescription,
  }
  CSS_MAP = {
    [0,2,1,2] => 'top',
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
    hidden.css_id = "info.festbetragsstufe.#{model.code(:cid)}"
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
    hidden.css_id = "info.zuzahlungsbefreit.#{model.code(:cid)}"
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
    link.href = "http://www.bkk.de/bkk/powerslave,id,1054,nodeid,.html"
    link
  end
  def opener(id)
    span = HtmlGrid::Span.new(nil, @session, self)
    span.value = @lookandfeel.lookup(:more)
    span.onclick = "dojo.lfx.chain(dojo.lfx.toggle.fade.show('%s', 1000), dojo.lfx.toggle.fade.hide(this, 1000)).play()" % id
    span.css_class = 'opener'
    span
  end
  def opener_festbetragsstufe(model)
    opener("info.festbetragsstufe.#{@model.code(:cid)}")
  end
  def opener_zuzahlungsbefreit(model)
    opener("info.zuzahlungsbefreit.#{model.code(:cid)}")
  end
  def price_difference(model)
    lnk = HtmlGrid::Link.new(:price_difference, model, @session, self)
    if(lnk.value = super)
      lnk.href = "ftp://ftp.dimdi.de/pub/amg/satzbeschr_011006.pdf"
    end
    lnk.label = true
    lnk
  end
end
class Packages < View::List
  include PackageMethods
  include ProductMethods
  include View::Google
  EMPTY_LIST_KEY = :empty_packages
  def init
    @components = @lookandfeel.result_components
    @components.each { |key, val|
      css_map.store(key, val.to_s)
    }
    @css_head_map = @css_map
    super
  end
  def atc(model)
    description = @lookandfeel.lookup(:atc_unknown)
    if(atc = model.atc)
      description = sprintf("%s (%s)", atc.name.send(@session.language),
                            atc.code)

    end
    sprintf("%s - %i %s", description, model.size, 
            @lookandfeel.lookup(:packages))
  end
  def code_prescription(model)
    span = HtmlGrid::Span.new(model, @session, self)
    if((code = model.code(:prescription)) && code.value)
      span.value = @lookandfeel.lookup(:prescription_needed)
      span.css_class = 'prescription'
    else
      span.value = @lookandfeel.lookup(:prescription_free)
      span.css_class = 'otc'
    end
    span
  end
  def compose_empty_list(offset)
    if(key = @model.error)
      fill_row(offset, key, 'warn')
    else
      super(offset, 'info')
    end
  end
  def compose_list(model=@model, offset=[0,0])
    @model.each { |part|
      offset = compose_subheader(part, offset)
      offset = super(part, offset)
    }
  end
  def compose_subheader(model, offset)
    @grid.add(atc(model), *offset)
		@grid.set_colspan(offset.at(0), offset.at(1), full_colspan)
    @grid.set_row_attributes({'class' => 'groupheader'}, 
                             offset.at(1), 1)
    resolve_offset(offset, OFFSET_STEP)
  end
  def package_infos(model)
    @info_id ||= 0
    @info_id += 1
    span = HtmlGrid::Span.new(model, @session, self)
    span.css_id = "package_infos#@info_id"
    infos = [ price_difference(model),
      code_festbetragsgruppe(model), code_festbetragsstufe(model),
      code_zuzahlungsbefreit(model),
      code_prescription(model) ].compact
    span.value = infos.zip(Array.new(infos.size - 1, ' / '))
    span.dojo_tooltip = @lookandfeel._event_url(:package_infos,
                                                [:pzn, model.code(:cid)])
    span
  end
  def query_args
    [:dstype, @model.dstype]
  end
end
class ResultComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => :title_found, 
    [0,1] => "explain_compare", 
    [0,2] => InlineSearch, 
    [0,3] => Packages, 
    [0,4] => Legend,
  }
  CSS_ID_MAP = ['result-found', 'explain-compare', 'result-search', 
                'result-list', 'legend' ]
  CSS_MAP = { 1 => 'before-searchbar', 3 => 'result' }
  def title_found(model)
    @lookandfeel.lookup(:title_found, @model.query, @model.total)
  end
end
class Result < Template
  CONTENT = ResultComposite
end
      end
    end
  end
end
