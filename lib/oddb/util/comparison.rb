#!/usr/bin/env ruby
# Util::Comparison -- de.oddb.org -- 13.03.2007 -- hwyss@ywesee.com

require 'delegate'

module ODDB
  module Util
    class Comparison < SimpleDelegator
      attr_reader :difference, :absolute, :factor, 
        :difference_exfactory, :absolute_exfactory, :factor_exfactory
      def initialize(package, original)
        @package = package
        psize = package.size.to_f
        pprice = package.price(:public).to_f
        osize = original.size.to_f
        oprice = original.price(:public).to_f
        unless((psize * pprice * osize * oprice) == 0)
          @factor = psize / osize
          @absolute = pprice - oprice
          @difference = ((osize * pprice) / (psize * oprice) - 1) * 100
        end
        pprice = package.price(:exfactory).to_f
        oprice = original.price(:exfactory).to_f
        unless((psize * pprice * osize * oprice) == 0)
          @factor_exfactory = psize / osize
          @absolute_exfactory = pprice - oprice
          @difference_exfactory = ((osize * pprice) / (psize * oprice) - 1) * 100
        end
        super(package)
      end
      def is_a?(mod)
        super || @package.is_a?(mod)
      end
    end
  end
end
