#!/usr/bin/env ruby
# Drugs::Sequence -- de.oddb.org -- 31.08.2006 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Drugs
    class Sequence < Model
      attr_accessor :marketable, :fachinfo_url, :patinfo_url
      belongs_to :atc, delegates(:ddds)
      belongs_to :product, delegates(:company)
      has_many :compositions, 
        delegates(:active_agents, :doses, :substances),
        on_delete(:cascade)
      has_many :feedbacks, on_delete(:cascade)
      has_many :packages, on_delete(:cascade), on_save(:cascade)
      is_coded
      multilingual :name
      m10l_document :fachinfo
      m10l_document :patinfo
      def comparable?(other)
        other.is_a?(Sequence) && compositions == other.compositions
      end
      def comparables
        atc.sequences.select { |sequence|
          comparable?(sequence)
        }
      end
      def ddds # ddds depend on the sequence's Route of Administration
        forms = galenic_forms
        if(forms.size == 1 && (atc_class = atc) \
           && (group = forms.first.group) \
           && (roa = group.administration))
          atc_class.ddds.select { |ddd| 
            ddd.administration == roa }
        else
          []
        end
      end
      def galenic_forms
        compositions.collect { |comp| comp.galenic_form }.compact.uniq
      end
      def identical?(other)
        comparable?(other) && other.product == product \
          && compositions.each_with_index { |comp, idx| 
          unless(comp.galenic_form.eql?(other.compositions.at(idx).galenic_form))
            return false
          end
        } && true
      end
      def include?(substance, dose=nil, unit=nil)
        compositions.any? { |comp|
          comp.include?(substance, dose, unit)
        }
      end
      def registration
        code(:registration, 'EU')
      end
    end
  end
end
