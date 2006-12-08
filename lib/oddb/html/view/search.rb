#!/usr/bin/env ruby
# Html::View::Search -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'htmlgrid/divform'
require 'htmlgrid/reset'

module ODDB
  module Html
    module View
class SearchBar < HtmlGrid::InputText
  def init
    super
    val = @lookandfeel.lookup(:query_info)
    if(@value.nil? || @value.is_a?(StandardError))
      txt_val = if(@session.respond_to?(:persistent_user_input))
        @session.persistent_user_input(@name) 
      end || val
      @attributes.store('value', txt_val)
    end
    @attributes.update({
      'onFocus'  =>  "if (value=='#{val}') { value='' };",
      'onBlur'  =>  "if (value=='') { value='#{val}' };",
      'id'      =>  "searchbar",
    })
    args = [@name, '']
    submit = @lookandfeel._event_url(@container.event, args)
    script = "if(#{@name}.value!='#{val}'){"
    script << "var href = '#{submit}'"
    script << "+escape(#{@name}.value.replace(/\\//, '%2F'));"
    script << "if(this.search_type)"
    script << "href += '/search_type/' + this.search_type.value;"
    #script << "href += '#best_result';"
    script << "document.location.href=href; } return false"
    self.onsubmit = script
  end
end
class Search < HtmlGrid::DivForm
  EVENT = :search
  FORM_NAME = 'search'
  COMPONENTS = {
    [0,0] => :query,
    [0,1] => :submit,
    [1,1] => :reset,
    [0,2] => "explain_search",
    [0,3] => :social_bookmarks,
  }
  SYMBOL_MAP = {
    :query => SearchBar,
    :reset => HtmlGrid::Reset,
  }
  CSS_MAP = {2 => "explain"}
  SOCIAL_BOOKMARKS = [
    [ :sb_delicious, "http://del.icio.us/post?url=%s&title=%s" ],
    [ :sb_stumble, "http://www.stumbleupon.com/submit?url=%s&title=%s" ],
    [ :sb_digg, "http://digg.com/submit?phase=2&url=%stitle=%s" ],
  ]
  def social_bookmarks(model)
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
  EVENT = :search
  COMPONENTS = {
    [0,0] => :query,
    [1,0] => :submit,
    [2,0] => :reset,
  }
  SYMBOL_MAP = {
    :query => SearchBar,
    :reset => HtmlGrid::Reset,
  }
end
    end
  end
end
