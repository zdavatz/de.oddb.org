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
    script << "href += '#best_result';"
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
  }
  SYMBOL_MAP = {
    :query => SearchBar,
    :reset => HtmlGrid::Reset,
  }
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
