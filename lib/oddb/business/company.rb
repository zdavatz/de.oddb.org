#!/usr/bin/env ruby
# ODDB::Business::Company -- de.oddb.org -- 22.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Business
    class Company < Model
      has_many :products, delegates(:packages)
      multilingual :name
      def packages
        products.inject([]) { |memo, prod|
          memo.concat(prod.packages)
        }
      end
    end
  end
end
