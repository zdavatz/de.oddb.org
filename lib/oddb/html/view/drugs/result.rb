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
  def ikscat(model)
    span = HtmlGrid::Span.new(model, @session, self)
    span.value = code = model.ikscat.to_s
    if(code =~ /[AB]/)
      span.css_class = 'prescription'
    else
      span.css_class = 'otc'
    end
    span
  end
  def infos_local(model)
    code = model.code(:cid)
    span = HtmlGrid::Span.new(model, @session, self)
    span.css_id = "package_infos#{code}"
    infos = [ code_festbetragsgruppe(model), 
      code_festbetragsstufe(model), code_zuzahlungsbefreit(model),
      code_prescription(model) ].compact
    span.value = infos.zip(Array.new(infos.size - 1, ' / '))
    span.dojo_tooltip = @lookandfeel._event_url(:package_infos, 
                                                [:pzn, code])
    span
  end
  def infos_remote(model)
    span = HtmlGrid::Span.new(model, @session, self)
    infos = [ ikscat(model) ]
    uid = model.uid
    if(model.sl_entry)
      infos.unshift(@lookandfeel.lookup(:ch_sl))
    end
    span.css_id = "package_infos#{uid}"
    span.dojo_tooltip = @lookandfeel._event_url(:remote_infos, 
                                                [:uid, uid])
    span.value = infos.zip(Array.new(infos.size - 1, ' / '))
    span
  end
  def package_infos(model)
    if(model.is_a?(Remote::Drugs::Package))
      infos_remote(model)
    else
      infos_local(model)
    end
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
  JAVASCRIPTS = ['opener']
end
      end
    end
  end
end
