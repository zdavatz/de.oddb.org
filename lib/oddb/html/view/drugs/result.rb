#!/usr/bin/env ruby
# Html::View::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/div'
require 'htmlgrid/divform'
require 'htmlgrid/errormessage'
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
class AtcAssign < HtmlGrid::DivForm
  COMPONENTS = { [0,0,0] => :toggle, [0,0,1] => :atc_assign }
  EVENT = :atc_assign
  FORM_ID = 'atc-assign-form'
  def atc_assign(model)
    input = HtmlGrid::InputText.new(:code, model, @session, self)
    style = 'margin-left: 4px;'
    style << ' display: none;' unless @session.error(:atc_assign)
    input.set_attribute('style', style)
    input.css_id = 'atc-assign'
    input
  end
  def hidden_fields(context)
    %w{query dstype}.inject(super) { |memo, key| 
      memo << context.hidden(key, @session.persistent_user_input(key))
    }
  end
  def toggle(model)
    link = HtmlGrid::Link.new(:atc_assign, model, @session, self)
    unless @session.error(:atc_assign)
      link.onclick = "dojo.lfx.toggle.fade.show('atc-assign', 500); this.onclick=null;"
    end
    link.css_id = 'atc-assign-toggle'
    link
  end
end
class Pager < HtmlGrid::Div
  CSS_CLASS = 'pager'
  def init
    super
    @value = [@lookandfeel.lookup(:pager, @model.page + 1, 
                                  @model.page_count)]
    @value.push(' ', link('<<', @model.page))
    1.upto(@model.page_count) { |page|
      @value.push(' ', link(page.to_s, page))
    }
    @value.push(' ', link('>>', @model.page + 2))
  end
  def link(text, pos)
    link = HtmlGrid::Link.new(:pager, @model, @session, self)
    link.value = text
    unless([0, @model.page.next, @model.page_count.next].include?(pos))
      args = @session.state.direct_event
      event = args.shift
      args.push(:page, pos)
      link.href = @lookandfeel._event_url(event, args)
    else
      link.css_class = 'current_page'
    end
    link
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
    parts = []
    atc = model.atc
    if(atc.nil? \
       && @session.allowed?('login', ODDB.config.auth_domain + '.Admin'))
      parts.push AtcAssign.new(atc, @session, self)
    end
    if(atc)
      description = sprintf("%s (%s)", 
                            atc.name.send(@session.language), atc.code)
      parts.push ddd_link(atc)
    end
    txt = sprintf("%s - %i %s", description, model.size,
                  @lookandfeel.lookup(:packages))
    if(@model.overflow?) 
      parts.push atc_opener(atc, txt)
    else
      parts.push txt
    end
    if(@model.overflow? && @model.paged?)
      parts.push Pager.new(@model, @session, self)
    end
    parts.reverse
  end
  def atc_assign
    div = HtmlGrid::DivForm.new(nil, @session, self)
    div.extend(HtmlGrid::FormMethods)
    div.value = [
      @lookandfeel.lookup(:atc_assign),
      HtmlGrid::Input.new(:atc_assign, nil, @session, self),
    ]
    div
  end
  def atc_code(model)
    model ? model.code : 'X'
  end
  def atc_opener(model, txt)
    code = atc_code(model)
    if(code == @session.persistent_user_input(:code))
      link = HtmlGrid::Link.new(code, model, @session, self)
      unless(code == 'X')
        link.href = @lookandfeel._event_url(:search, [:query, code, 
                                            :dstype, :compare])
      end
      link.value = txt
      link
    else
      variable_link(:code, code, txt, code)
    end
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
    code = @session.persistent_user_input(:code)
    if(model.overflow?)
      offset = compose_row(display_switcher(model), offset, 
                           {'id' => 'display-switcher'})
    end
    @model.each { |part|
      ccode = atc_code(part.atc)
      offset = compose_subheader(part, offset, 
                                 model.overflow? && ccode == code)
      if(@model.show_details? || (ccode == code))
        offset = super(part, offset)
      end
    }
  end
  def compose_row(content, offset, attrs={})
    @grid.add(content, *offset)
		@grid.set_colspan(offset.at(0), offset.at(1), full_colspan)
    @grid.set_row_attributes(attrs, offset.at(1), 1)
    resolve_offset(offset, OFFSET_STEP)
  end
  def compose_subheader(model, offset, selected=false)
    attrs = {'class' => 'groupheader'}
    if(selected)
      attrs.store('id', 'selected')
    end
    compose_row(atc(model), offset, attrs)
  end
  def ddd_link(atc)
    while(atc && !atc.interesting? && (code = atc.parent_code))
      atc = ODDB::Drugs::Atc.find_by_code(code)
    end
    if(atc && atc.interesting?)
      link = HtmlGrid::Link.new(:who_ddd, atc, @session, self)
      link.href = @lookandfeel._event_url(:ddd, [:code, atc.code])
      link.css_class = 'who-ddd square'
      link
    end
  end
  def display_switcher(model)
    disp = @session.cookie_set_or_get(:display)
    disp = (disp == 'paged') ? 'grouped' : 'paged'
    link = variable_link(:display, disp, 
                         @lookandfeel.lookup("display_#{disp}"))
    link
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
  def variable_link(key, value, text, anchor=nil)
    link = HtmlGrid::Link.new(key, @model, @session, self)
    args = @session.state.direct_event
    event = args.shift
    args.push(key, value)
    link.href = @lookandfeel._event_url(event, args, anchor)
    link.value = text
    link
  end
end
class ResultComposite < HtmlGrid::DivComposite
  include HtmlGrid::ErrorMessage
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
  def init
    super
    error_message
  end
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
