#!/usr/bin/env ruby
# Html::View::Search -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/divform'
require 'htmlgrid/reset'
require 'htmlgrid/select'

module ODDB
  module Html
    module View
module SearchMethods
  def dstype(model)
    select = HtmlGrid::Select.new(:dstype, model, @session, self)
		select.set_attribute('onChange', 'this.form.onsubmit();')
		select.selected = @session.persistent_user_input(:dstype)
    select
  end
end
class SearchBar < HtmlGrid::InputText
  def init
    super
    self.onload = "document.getElementById('searchbar').focus();"
    val = @lookandfeel.lookup(:query_info)
    txt_val = @session.persistent_user_input(@name) || val
    @attributes.store('value', txt_val)
    @attributes.update({
      'onFocus'  =>  "if (value=='#{val}') { value='' };",
      'onBlur'  =>  "if (value=='') { value='#{val}' };",
      'id'      =>  "searchbar",
    })
    args = [@name, '']
    submit = @lookandfeel._event_url(@container.event, args)
    script = "if(#{@name}.value!='#{val}'){"
    script << "var href = '#{submit}'"
    script << "+encodeURIComponent(#{@name}.value.replace(/\\//, '%2F'));"
    script << "if(this.dstype)"
    script << "href += '/dstype/' + this.dstype.value;"
    #script << "href += '#best_result';"
    script << "document.location.href=href; } return false"
    self.onsubmit = script
  end
end
class Search < HtmlGrid::DivForm
  include SearchMethods
  EVENT = :search
  FORM_NAME = 'search'
  COMPONENTS = {
    [0,0] => 'dstype',
    [0,1] => :dstype,
    [0,2] => :query,
    [0,3] => :submit,
    [1,3] => :reset,
    [0,4] => "explain_search",
    [0,5] => :social_bookmarks,
    [0,6] => :screencast,
  }
  SYMBOL_MAP = {
    :query  => SearchBar,
    :reset  => HtmlGrid::Reset,
  }
  CSS_MAP = {4 => "explain", 6 => "explain"}
  SOCIAL_BOOKMARKS = [
    [ :sb_delicious, "http://del.icio.us/post?url=%s&title=%s" ],
    [ :sb_stumble, "http://www.stumbleupon.com/submit?url=%s&title=%s" ],
    [ :sb_digg, "http://digg.com/submit?phase=2&url=%stitle=%s" ],
    [ :sb_simpy, 
      "http://www.simpy.com/simpy/LinkAdd.do?href=%s&note=%s"],
  ]
  def screencast(model)
    if @lookandfeel.enabled?(:screencast)
      link = HtmlGrid::Link.new(:screencast, model, @session, self)
      link.href = @lookandfeel.lookup(:screencast_url)
      link
    end
  end
  def social_bookmarks(model)
    return unless @lookandfeel.enabled?(:social_bookmarks)
    url = @lookandfeel.base_url
    title = escape(@lookandfeel.lookup(:explain_search))
    SOCIAL_BOOKMARKS.collect { |key, fmt|
      span = HtmlGrid::Span.new(model, @session, self)
      link = HtmlGrid::Link.new(key, model, @session, self)
      link.href = sprintf(fmt, url, title)
      span.css_class = 'social'
      span.css_id = key.to_s[3..-1]
      span.value = link
      span
    }
  end
end
class InlineSearch < HtmlGrid::DivForm
  include SearchMethods
  EVENT = :search
  COMPONENTS = {
    [0,0] => :query,
    [1,0] => :dstype,
  }
  SYMBOL_MAP = {
    :query => SearchBar,
  }
end
    end
  end
end
