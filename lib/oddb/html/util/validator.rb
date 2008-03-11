#!/usr/bin/env ruby
# Html::Util::Validator -- de.oddb.org -- 02.11.2006 -- hwyss@ywesee.com

require 'sbsm/validator'

module ODDB
  module Html
    module Util
class Validator < SBSM::Validator
  BOOLEAN = [ :email_public, :item_good_experience, :item_good_impression, 
              :item_recommended, :item_helps, ]
  ENUMS = {
    :display   => ['paged', 'grouped'],
    :dstype    => ['tradename', 'compare', 'substance', 'company'],
    :range     => ("A".."Z").to_a.push('0-9'),
    :salutation => [nil, "salutation_f", "salutation_m"],
    :sortvalue => [ 'active_agents', 'atc', 'code_festbetragsstufe',
      'code_zuzahlungsbefreit', 'company', 'ddd_prices', 'difference',
      'doses', 'package_infos', 'price_festbetrag', 'price_difference',
      'price_public', 'product', 'size', 
    ],
  }
  EVENTS = [ :ajax_autofill, :atc_browser, :collect, :ddd, :explain_ddd_price,
             :explain_price, :fachinfo, :feedback, :checkout, :compare,
             :compare_remote, :home, :login, :login_, :logout, :package,
             :package_infos, :patinfo, :proceed_poweruser, :products,
             :remote_infos, :search, :sort, :update ]
  NUMERIC = [ :days, :offset, :pzn ]
  STRINGS = [ :captcha, :chapter, :code, :fi_url, :invoice, :message, :name,
              :name_first, :name_last, :pi_url, :query, :uid ]
  def page(value) 
    if(num = validate_numeric(:page, value))
      # pages are 1-based for the human user
      [num.to_i - 1, 0].max
    end
  end
end
    end
  end
end
