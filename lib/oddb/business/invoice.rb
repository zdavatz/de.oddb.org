#!/usr/bin/env ruby
# Util::Invoice -- de.oddb.org -- 21.01.2008 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Business
    class Invoice < Model
      has_many :items
      attr_accessor :yus_name, :ydim_id, :status, :ipn, :currency
      attr_reader :time
      class Item
        attr_reader :type, :text, :quantity, :price, :vat, :time
        attr_accessor :expiry_time
        def initialize(type, text, quantity, unit, price)
          @type, @text, @quantity, @unit, @price \
            = type, text, quantity.to_i, unit.to_s, price.to_f
          @time = Time.now
        end
        def expired?
          @expiry_time && @expiry_time < Time.now
        end
        def total_brutto
          total_netto + vat
        end
        def total_netto
          @price * @quantity
        end
        def vat
          total_netto * ODDB.config.vat / 100
        end
        def ydim_data
          {
            :expiry_time	=>	@expiry_time,
            :price				=>	@price,
            :quantity			=>	@quantity,
            :text					=>	@text,
            :time					=>	@time,
            :unit					=>	@unit,
          }
        end
      end
      def initialize
        @items = []
        @salt = generate_salt
        @time = Time.now
        @yus_name = ''
        @currency = 'EUR'
      end
      def add(*args)
        add_item Item.new(*args)
      end
      def id
        @id ||= Digest::MD5.hexdigest @time.strftime("%c") << @salt << @yus_name
      end
      def paid_for?(text)
        @status == 'completed' && @items.any? { |item| item.text == text }
      end
      def total_brutto
        @items.inject(Util::Money.new(0)) { |memo, item| 
          memo + item.total_brutto
        }
      end
      def types
        @items.collect { |item| item.type }.compact.uniq
      end
      private
      def generate_salt
        salt = '' 
        8.times { salt << rand(255).chr }
        salt
      end
    end
  end
end
