#!/usr/bin/env ruby
# Html::Util::Validator -- de.oddb.org -- 02.11.2006 -- hwyss@ywesee.com

require 'sbsm/validator'

module ODDB
  module Html
    module Util
class Validator < SBSM::Validator
  EVENTS = [ :home, :search, :sort ]
  STRINGS = [ :query ]
  ENUMS = {
    :sortvalue => [ 'atc', 'company', 'doses', 'festbetrag',
      'festbetragsstufe', 'price_public', 'product', 'zuzahlungsbefreit',
      'size', 
    ],
  }
end
    end
  end
end
