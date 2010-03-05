#!/usr/bin/env ruby
# Html::State::RegisterDownload -- de.oddb.org -- 28.07.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/util/need_all_input'
require 'oddb/html/view/register_download'

module ODDB
  module Html
    module State
class RegisterDownload < Global
  include Util::NeedAllInput
  VIEW = View::RegisterDownload
  def checkout_mandatory
    super.push :company_name, :address, :postal_code, :city,
               :phone, :business_area
  end
  def direct_event
    [:proceed_download]
  end
end
    end
  end
end
