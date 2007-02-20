#!/usr/bin/env ruby
# Drugs::Dose -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'oddb/util/quanty'

module ODDB
  module Drugs
    class Dose < Quanty
      include Comparable
      alias :qty :val 
      np = '-?[0-9]+(?:[.,][0-9]+)?' ## numerical pattern
      @@range_ptrn = %r{(#{np})\s*-\s*(#{np})}
      @@cnc_ptrn = %r{([^/]*)/\s*(#{np})\s*(.*)}
      def Dose.from_quanty(other)
        Dose.new(other.val, other.unit)
      end
      def initialize(qty, unit=nil)
        qty_str = ''
        if(match = @@range_ptrn.match(qty.to_s))
          qty = round(match[1].to_f)..round(match[2].to_f)
        end
        if(qty.is_a?(Range))
          qty_str = "#{qty.first}-#{qty.last}"
          qty = (qty.first + qty.last) / 2.0
          @not_normalized = [qty_str, unit].compact.join(' ')
        end
        if(match = @@cnc_ptrn.match(unit.to_s))
          qty_str = round(qty).to_s
          div = round(match[2])
          @not_normalized = [
            qty_str, 
            [match[1].strip, div].join(' / '), 
            match[3],
          ].join
          qty = qty.to_f/div.to_f
          unit = [match[1].strip,match[3].strip].join('/')
        end
        qty = round(qty)
        unit = unit.to_s.tr('L', 'l')
        fuzzy_retry = true
        strict_retry = true
        begin
          super(qty, unit)
        rescue StandardError => e
          if(fuzzy_retry)
            unit = unit[0,2]
            fuzzy_retry = false
            retry
          elsif(strict_retry)
            unit = ''
            strict_retry = false
            retry
          end
        end
      end
      def to_f
        begin
          super
        rescue RuntimeError
          @val * @fact.factor
        end
      end
      def to_i
        @val.to_i
      end
      def to_s
        @not_normalized or 
        begin
          val = if(@val.is_a? Float)
            sprintf('%.3f', @val).gsub(/0+$/, '')
          else
            @val
          end
          [val, @unit].join(' ')
        end
      end
      def * (other)
        Dose.from_quanty(super)
      end
      def + (other)
        Dose.from_quanty(super)
      end
      def / (other)
        Dose.from_quanty(super)
      end
      def - (other)
        Dose.from_quanty(super)
      end
      def <=>(other)
        return -1 unless(other.is_a?(Quanty))
        begin
          (@val * 1000).round <=> (adjust(other) * 1000).round
        rescue StandardError
          @unit <=> other.unit
        end
      end
      private
      def round(qty)
        qty = qty.to_s.gsub(/'/, '').gsub(',', '.')
        if(qty.to_f == qty.to_i)
          qty.to_i
        else
          qty.to_f
        end
      end
    end
  end
end
