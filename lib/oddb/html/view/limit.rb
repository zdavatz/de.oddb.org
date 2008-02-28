#!/usr/bin/env ruby
# Html::View::Limit -- de.oddb.org -- 20.12.2007 -- hwyss@ywesee.com

require 'htmlgrid/divcomposite'
require 'htmlgrid/errormessage'
require 'oddb/html/view/template'
require 'oddb/html/view/login'

module ODDB
  module Html
    module View
class LimitForm < HtmlGrid::Form
  include HtmlGrid::ErrorMessage
  COMPONENTS = {
    [0,0]  =>  :query_limit_poweruser_365,
    [2,0]  =>  :query_limit_poweruser_a,
    [0,1]  =>  :query_limit_poweruser_30,
    [2,1]  =>  :query_limit_poweruser_b,
    [0,2]  =>  :query_limit_poweruser_1,
    [2,2]  =>  :query_limit_poweruser_c,
    [2,3]  =>  :submit,
  }
  LABELS = true
  LEGACY_INTERFACE = false
  EVENT = :proceed_poweruser
  def init
    super
    error_message
  end
  def query_limit_poweruser_a(model)
    query_limit_poweruser_txt(:query_limit_poweruser_a, 365)
  end
  def query_limit_poweruser_b(model)
    @lookandfeel.lookup(:query_limit_poweruser_b, ODDB.config.query_limit,
      ODDB::Util::Money.new(ODDB.config.prices["org.oddb.de.view.30"]))
  end
  def query_limit_poweruser_c(model)
    query_limit_poweruser_txt(:query_limit_poweruser_c, 1)
  end
  def query_limit_poweruser_txt(key, duration)
    price = ODDB::Util::Money.new ODDB.config.prices["org.oddb.de.view.#{duration}"]
    @lookandfeel.lookup(key, price)
  end
  def query_limit_poweruser_1(model)
    query_limit_poweruser_radio(1)
  end
  def query_limit_poweruser_30(model)
    query_limit_poweruser_radio(30)
  end
  def query_limit_poweruser_365(model)
    query_limit_poweruser_radio(365)
  end
  def query_limit_poweruser_radio(value)
    radio = HtmlGrid::InputRadio.new('days', @model, @session, self)
    radio.value = value
    radio
  end
end
class LimitComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => InlineSearch, 
    [0,1] => :query_limit,
    [0,2] => 'query_limit_welcome',
    [0,2] => 'query_limit_new_user',
    [1,2] => :query_limit_more_info,
    [0,3] => :query_limit_explain,
    [0,4] => 'query_limit_poweruser',
    [0,5] =>  LimitForm,
    [0,6] => 'query_limit_login',
    [0,7] => LoginForm,
    [0,8] => 'query_limit_thanks',
    [0,9] => 'query_limit_thanks0',
    [1,9] => :query_limit_email,
    [2,9] => 'query_limit_thanks1',
  }
  CSS_ID_MAP = ['result-search', 'title']
  CSS_MAP = { 1 => 'heading', 2 => 'divider', 3 => 'explain',
              4 => 'explain', 6 => 'divider', 8 => 'divider', 9 => 'explain' }
  def query_limit(model)
    @lookandfeel.lookup(:query_limit, ODDB.config.query_limit)
  end
  def query_limit_download(model)
    link = HtmlGrid::Link.new(:query_limit_download, 
      model, @session, self)
    link.value = link.href = @lookandfeel._event_url(:download_export)
    link
  end
  def query_limit_email(model)
    link = HtmlGrid::Link.new(:ywesee_contact_email, 
      model, @session, self)
    link.href = @lookandfeel.lookup(:ywesee_contact_href)
    link
  end
  def query_limit_explain(model)
    @lookandfeel.lookup(:query_limit_explain, @session.remote_ip,
                        ODDB.config.query_limit)
  end
  def query_limit_more_info(model)
    link = HtmlGrid::Link.new(:query_limit_more_info, model, @session, self)
    link.href = "http://wiki.oddb.org/wiki.php/Main/DeODDB"
    link
  end
end
class Limit < Template
  CONTENT = LimitComposite
end
    end
  end
end
