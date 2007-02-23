#!/usr/bin/env ruby
# Import::Csv::ProductInfos -- de.oddb.org -- 13.02.2007 -- hwyss@ywesee.com

require 'csv'
require 'oddb/business/company'
require 'oddb/drugs/package'
require 'oddb/import/import'
require 'oddb/util/code'


module ODDB
  module Import
    module Csv
class ProductInfos < Import
  def import(io)
    skip = @skip_rows
    CSV::IOReader.new(io, ';').each { |row|
      if(skip > 0)
        skip -= 1
      else
        import_row(row)
      end
    }
  end
  def import_row(row)
    pzn = u(row.at(0).to_i.to_s)
    if(package = Drugs::Package.find_by_code(:type    => 'cid',
                                             :value   => pzn,
                                             :country => 'DE'))
      presc = row.at(2) == 'Rezeptpflichtig'
      if(code = package.code(:prescription))
        code.value = presc
      else
        package.add_code Util::Code.new(:prescription, presc, 'DE')
        package.save
      end
      product = package.product
      unless(product.company)
        product.company = import_company(row)
        product.save
      end
    end
  end
  def import_company(row)
    name = company_name(row.at(9))
    company = Business::Company.find_by_name(name) 
    if(company.nil?)
      company = Business::Company.new
      company.name.de = name
    end
    company
  end
end
    end
  end
end
