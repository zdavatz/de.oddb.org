#!/usr/bin/env ruby
# Html::Util::Validator -- de.oddb.org -- 02.11.2006 -- hwyss@ywesee.com

require 'sbsm/validator'

module ODDB
  module Html
    module Util
class Validator < SBSM::Validator
  BOOLEAN = [ :code_prescription, :code_zuzahlungsbefreit, :email_public,
              :item_good_experience, :item_good_impression, :item_recommended,
              :item_helps, ]
  ENUMS = {
    :business_area => [ nil, 'ba_hospital', 'ba_pharma', 'ba_insurance',
                        'ba_doctor', 'ba_health', 'ba_info' ],
    :compression   => [ 'compr_zip', 'compr_gz' ],
    :display   => ['paged', 'grouped'],
    :dstype    => ['tradename', 'compare', 'substance', 'company',
                   'indication'],
    :range     => ("A".."Z").to_a.push('0-9'),
    :salutation => [nil, "salutation_f", "salutation_m"],
    :sortvalue => [ 'active_agents', 'atc', 'code_festbetragsstufe',
      'code_zuzahlungsbefreit', 'company', 'ddd_prices', 'difference',
      'doses', 'package_infos', 'price_festbetrag', 'price_difference',
      'price_public', 'product', 'size', 
    ],
  }
  EVENTS = [ :ajax_autofill, :ajax_create_active_agent,
             :ajax_create_composition, :ajax_create_part,
             :ajax_delete_active_agent, :ajax_delete_composition,
             :ajax_delete_part, :atc_assign, :atc_browser, :checkout, :collect,
             :compare, :compare_remote, :ddd, :delete, :downloads,
             :explain_ddd_price, :explain_price, :fachinfo, :feedback, :home,
             :login, :login_, :logout, :new_package, :new_sequence, :package,
             :package_infos, :patinfo, :proceed_download, :proceed_export,
             :proceed_poweruser, :product, :products, :remote_infos, :search,
             :sequence, :sort, :update ]
  NUMERIC = [ :active_agent, :code_festbetragsgruppe,
              :code_festbetragsstufe, :composition, :days, :equivalence_factor,
              :months, :multi, :offset, :part, :price_exfactory,
              :price_festbetrag, :price_public, :sequence, :size  ]
  PATTERNS = {
    :atc => /[ABCGHJLMNPRSV](\d{2}([A-Z]([A-Z](\d{2})?)?)?)?/,
  }
  STRINGS = [ :address, :atc_name, :captcha, :chapter, :city, :code, :code_cid,
              :company, :company_name, :dose, :downloads, :fachinfo_url, :file,
              :galenic_form, :invoice, :message, :name, :name_first,
              :name_last, :patinfo_url, :phone, :postal_code, :pzn, :quantity,
              :query, :registration, :substance, :uid, :unit ]
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
