#!/usr/bin/env ruby
# Html::View::RegisterDownload -- de.oddb.org -- 28.07.2008 -- hwyss@ywesee.com

require 'oddb/html/view/template'
require 'oddb/html/view/paypal/register_form'

module ODDB
  module Html
    module View
class RegisterDownloadComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => "download",
    [0,1] => "download_descr",
    [0,2] => PayPal::ExtendedRegisterForm,
    [1,2] => :invoice_items,
  }
  CSS_ID_MAP = ['title']
  CSS_MAP = { 1 => 'explain' }
  def invoice_items(model)
    PayPal::InvoiceItems.new(model.items, @session, self)
  end
end
class RegisterDownload < Template
  JAVASCRIPTS = ['autofill']
  CONTENT = RegisterDownloadComposite
end
    end
  end
end
