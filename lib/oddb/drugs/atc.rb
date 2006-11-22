#!/usr/bin/env ruby
# Drugs::Atc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Atc < Model
      has_many :ddds
      has_many :products
      attr_reader :code
      multilingual :name
      def initialize(code)
        @code = code
      end
    end
  end
end
