#!/usr/bin/env ruby
# Html::View::RegisterExport -- de.oddb.org -- 28.07.2008 -- hwyss@ywesee.com

require 'oddb/html/view/template'
require 'oddb/html/view/paypal/register_form'

module ODDB
  module Html
    module View
class RegisterExportComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => "export",
    [0,1] => "export_descr",
    [0,2] => PayPal::RegisterForm,
    [1,2] => :invoice_items,
  }
  CSS_ID_MAP = ['title']
  CSS_MAP = { 1 => 'explain' }
  def invoice_items(model)
    PayPal::InvoiceItems.new(model.items, @session, self)
  end
end
class RegisterExport < Template
  JAVASCRIPTS = ['autofill']
  CONTENT = RegisterExportComposite
end
    end
  end
end
