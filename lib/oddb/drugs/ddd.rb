#!/usr/bin/env ruby
# Drugs::Ddd -- de.oddb.org -- 20.11.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Ddd < Model
      attr_reader :administration
      attr_accessor :dose, :comment
      belongs_to :atc
      def initialize(administration)
        @administration = administration
      end
      def to_s
        if(@comment)
          sprintf("%s: %s (%s)", @administration, @dose, @comment)
        else
          sprintf("%s: %s", @administration, @dose)
        end
      end
    end
  end
end
