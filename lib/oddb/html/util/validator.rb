#!/usr/bin/env ruby
# Html::Util::Validator -- de.oddb.org -- 02.11.2006 -- hwyss@ywesee.com

require 'sbsm/validator'

module ODDB
  module Html
    module Util
class Validator < SBSM::Validator
  ENUMS = {
    :dstype    => ['compare', 'tradename', 'substance'],
    :range     => ("A".."Z").to_a.push('0-9'),
    :sortvalue => [ 'active_agents', 'atc', 'code_festbetragsstufe',
      'code_zuzahlungsbefreit', 'company', 'difference', 'doses',
      'price_festbetrag', 'price_difference', 'price_public',
      'product', 'size', 
    ],
  }
  EVENTS = [ :compare, :compare_remote, :home, :package, :products,
             :search, :sort ]
  NUMERIC = [ :offset, :pzn ]
  STRINGS = [ :query, :uid ]
end
    end
  end
end
