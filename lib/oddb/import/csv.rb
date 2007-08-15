#!/usr/bin/env ruby
# Import::Csv::ProductInfos -- de.oddb.org -- 13.02.2007 -- hwyss@ywesee.com

require 'csv'
require 'oddb/business/company'
require 'oddb/drugs/active_agent'
require 'oddb/drugs/composition'
require 'oddb/drugs/dose'
require 'oddb/drugs/package'
require 'oddb/drugs/part'
require 'oddb/drugs/substance'
require 'oddb/drugs/unit'
require 'oddb/import/import'
require 'oddb/util/code'

module ODDB
  module Import
    module Csv
class ProductInfos < Import
  def initialize
    super
    @count = 0
    @created = 0
    @created_companies = 0
    @found = 0
  end
  def cell(row, idx)
    if((str = row.at(idx)) && !str.to_s.empty?)
      u(@@iconv.iconv(str.to_s))
    end
  end
  def import(io)
    skip = @skip_rows
    CSV::IOReader.new(io, ';').each { |row|
      if(skip > 0)
        skip -= 1
      else
        import_row(row)
      end
    }
    report
  end
  def import_row(row)
    pzn = u(row.at(0).to_i.to_s)
    @count += 1
    if(package = Drugs::Package.find_by_code(:type    => 'cid',
                                             :value   => pzn,
                                             :country => 'DE'))
      @found += 1
      modified = false
      name = cell(row, 1).gsub(/[A-Z .&+-]+/) { |part| 
        capitalize_all(part) }
      if(package.name != name)
        modified = true
        package.name.de = name
      end
      presc = row.at(2) == 'Rezeptpflichtig'
      if(code = package.code(:prescription))
        if(code.value != presc)
          modified = true
          code.value = presc
        end
      else
        modified = true
        package.add_code Util::Code.new(:prescription, presc, 'DE')
      end
      import_dose(row, package) && modified = true
      package.save if(modified)
      import_size(row, package)
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
      @created_companies += 1
      company = Business::Company.new
      company.name.de = name
    end
    company
  end
  def import_dose(row, package)
    if(package.size == 1 && (sequence = package.sequence) \
       && sequence.compositions.size == 1 \
       && (match = cell(row, 1).match(/\d+([.,]\d+)?/)))
      dose = match[1] ? match[0].gsub(',', '.').to_f : match[0].to_i
      if(sequence.active_agents.size == 1)
        agent = sequence.active_agents.first
        size = row.at(3).to_i
        if(agent.dose.qty == size * dose)
          update_sequence(package, 
                          Drugs::Dose.new(dose, agent.dose.unit))
        end
      end
    end
  end
  def import_size(row, package)
    if(part = package.parts.first)
      dose, size, multi = row.at(3).to_s.split(/x/i, 3).reverse.compact
      unit = row.at(4).to_s
      if(unit != 'St')
        part.quantity = Drugs::Dose.new(dose, unit)
      elsif(multi.nil?)
        multi = size
        size = dose
      end
      multi = multi.to_i
      size = size.to_i
      part.multi = (multi > 0) ? multi : nil
      part.size = (size > 0) ? size : nil
      if(unitname = cell(row, 5))
        unit = Drugs::Unit.find_by_name(unitname)
        unless(unit)
          unit = Drugs::Unit.new  
          unit.name.de = unitname
          unit.save
        end
        part.unit = unit
      end
      part.save
    end
  end
  def update_sequence(package, dose)
    sequence = package.sequence
    existing = package.product.sequences.find { |seq|
      seq.doses == [dose]
    }
    if(existing)
      package.sequence = existing
      package.save
      if(sequence.packages.empty?)
        sequence.delete
      end
    elsif(sequence.packages.size == 1)
      agent = sequence.active_agents.first
      agent.dose = dose
      agent.save
    else
      @created += 1
      substance = sequence.active_agents.first.substance
      seq = Drugs::Sequence.new
      comp = Drugs::Composition.new
      agent = Drugs::ActiveAgent.new(substance, dose)
      comp.add_active_agent(agent)
      comp.save
      seq.add_composition(comp)
      seq.product = sequence.product
      package.sequence = seq
      package.save
    end
  end
  def report
    [
      sprintf("Checked %5i Lines", @count),
      sprintf("Updated %5i Packages", @found),
      sprintf("Created %5i Sequences", @created),
      sprintf("Created %5i Companies", @created_companies),
    ]
  end
end
    end
  end
end
