#!/usr/bin/env ruby
# Import::Dimdi -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'oddb/import/excel'
require 'oddb/util/code'
require 'oddb/drugs/galenic_form'
require 'oddb/drugs/product'
require 'oddb/drugs/substance'

module ODDB
  module Import
    class DimdiGalenicForm < Excel
      def import_row(row)
        abbr = cell(row, 0)
        description = capitalize_all(cell(row, 1))
        galenic_form = Drugs::GalenicForm.find_by_code(:value => abbr, 
                                                       :type => "galenic_form",
                                                       :country => 'DE')
        galenic_form ||= Drugs::GalenicForm.find_by_description(description)
        unless(galenic_form)
          galenic_form = Drugs::GalenicForm.new
          galenic_form.description.de = description
        end
        code = Util::Code.new("galenic_form", abbr, 'DE')
        unless(galenic_form.codes.include?(code))
          galenic_form.add_code(Util::Code.new("galenic_form", abbr, 'DE'))
        end
        galenic_form.save
        galenic_form
      end
    end
    class DimdiProduct < Excel
      def import_row(row)
        name = row.at(0).to_s
        product = Drugs::Product.find_by_name(name)
        unless(product)
          product = Drugs::Product.new
          product.name.de = name
        end
        product.save
      end
    end
    class DimdiSubstance < Excel
      def import_row(row)
        abbr = cell(row, 0)
        name = capitalize_all(cell(row, 1))
        substance = Drugs::Substance.find_by_code(:value   => abbr,
                                                  :type    => "substance",
                                                  :country => "DE")
        substance ||= Drugs::Substance.find_by_name(name)
        unless(substance)
          substance = Drugs::Substance.new
          substance.name.de = name
          substance.add_code(Util::Code.new("substance", abbr, 'DE'))
        end
        substance.save
        substance
      end
    end
  end
end
