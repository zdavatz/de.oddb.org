#!/usr/bin/env ruby
# Html::View::PayPal::Collect -- de.oddb.org -- 30.01.2008 -- hwyss@ywesee.com

require 'oddb/html/view/search'
require 'oddb/html/view/template'

module ODDB
  module Html
    module View
      module PayPal
class ReturnDownloads < HtmlGrid::List
	COMPONENTS = {
		[0,0]	=>	:download_link	
	}
	LEGACY_INTERFACE = false
	OMIT_HEADER = true
	STRIPED_BG = false
  include State::PayPal::Download
	def download_link(model)
    invoice = @container.model
		if model.expired?
			time = model.expiry_time
			timestr = (time) \
				? time.strftime(@lookandfeel.lookup(:time_format_long)) \
				: @lookandfeel.lookup(:paypal_e_invalid_time)
			@lookandfeel.lookup(:paypal_e_expired, model.text, timestr)
    elsif @session.allowed?('download',
                            "#{ODDB.config.auth_domain}.#{model.text}") \
            || invoice.status == 'completed'
      link = HtmlGrid::Link.new(:paypal_download, model, @session, self)
      args = [ :invoice, invoice.id,
               :file, compressed_download(model)]
      link.href = link.value = @lookandfeel._event_url(:collect, args)
      link
    elsif @session.allowed?('view', ODDB.config.auth_domain)
      @lookandfeel.lookup(:paypal_explain_poweruser)
    else
			link = HtmlGrid::Link.new(:paypal_explain_login1, model, @session, self)
			link.href = @lookandfeel._event_url(:login)
      [ 
        @lookandfeel.lookup(:paypal_explain_login0),  
        link, 
        @lookandfeel.lookup(:paypal_explain_login2),  
      ]
		end
	end
end
class CollectComposite < HtmlGrid::DivComposite
  COMPONENTS = {
    [0,0] => InlineSearch, 
    [0,1] => :title,
    [0,2] => :message,
    [0,3] => :download_links,
  }
  CSS_ID_MAP = ['result-search', 'title']
  CSS_MAP = { 2 => 'explain' }
  LEGACY_INTERFACE = false
  def message(model)
    key = if(model.nil?)
            :paypal_e_missing_invoice
          elsif(model.status == 'completed')
            suffix = @model.items.size == 1 ? @model.types.first : 'p'
            "paypal_msg_succ_#{suffix}"
          else
            :paypal_msg_unconfirmed
          end
    @lookandfeel.lookup key
  end
  def title(model)
    msg = @lookandfeel.lookup("paypal_#{model.status}".downcase) if model
    msg || @lookandfeel.lookup(:paypal_failed)
  end
  def download_links(model)
    if(model && model.status == 'completed')
      ReturnDownloads.new(model.items, @session, self)
    end
  end
end
class Collect < Template
  CONTENT = CollectComposite
  def http_headers
    headers = super
    if(@model && !@model.status)
      args = { :invoice => @model.id }
      url = @lookandfeel._event_url(:collect, args)
      headers.store('Refresh', "10; URL=#{url}")
    end
    headers
  end
end
      end
    end
  end
end
