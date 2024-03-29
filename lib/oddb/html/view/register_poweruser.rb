#!/usr/bin/env ruby
# Html::View::RegisterPowerUser -- de.oddb.org -- 21.01.2008 -- hwyss@ywesee.com

require 'oddb/html/view/template'
require 'oddb/html/view/paypal/register_form'

module ODDB
  module Html
    module View
class RegisterPowerUserComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => "poweruser",
    [0,1] => "poweruser_descr",
    [0,2] => PayPal::RegisterForm,
    [1,2] => :invoice_items,
  }
  CSS_ID_MAP = ['title']
  CSS_MAP = { 1 => 'explain' }
  def invoice_items(model)
    PayPal::InvoiceItems.new(model.items, @session, self)
  end
end
class RegisterPowerUser < Template
  JAVASCRIPTS = ['autofill']
  CONTENT = RegisterPowerUserComposite
end
    end
  end
end
