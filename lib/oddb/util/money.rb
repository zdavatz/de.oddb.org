#!/usr/bin/env ruby
# Util::Money -- de.oddb.org -- 14.11.2006 -- hwyss@ywesee.com

module ODDB
  module Util
class Money
  attr_reader :credits
  attr_accessor :type, :country
  include Comparable
  class << self
    def five
      @five ||= self.new(5)
    end
    def ten
      @ten ||= self.new(10)
    end
  end
  def initialize(amount, type=nil, country=nil)
    self.amount = amount
    self.type = type
    self.country = country
  end
  def amount=(amount)
    @amount = amount.to_f
    @credits = (@amount * 100).round
  end
  def country=(country)
    @country = country.to_s.upcase
  end
  def is_for?(type, country)
    @type == type.to_s.downcase && @country == country.to_s.upcase
  end
  def to_f
    @amount || (@credits.to_f / 100)
  end
  def to_s
    sprintf("%1.2f", to_f)
  end
  def type=(type)
    @type = type.to_s.downcase
  end
  def +(other)
    Money.new((@amount || to_f) + other.to_f)
  end
  def -(other)
    Money.new((@amount || to_f) - other.to_f)
  end
  def *(other)
    Money.new((@amount || to_f) * other.to_f)
  end
  def /(other)
    Money.new((@amount || to_f) / other.to_f)
  end
  def <=>(other)
    case other
    when Money
      @credits <=> other.credits
    else
      to_f <=> other.to_f
    end
  end
end
  end
end
