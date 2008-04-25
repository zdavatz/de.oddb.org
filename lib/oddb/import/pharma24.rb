#!/usr/bin/env ruby
# Import::Pharma24 -- de.oddb.org -- 21.04.2008 -- hwyss@ywesee.com

require 'oddb/import/import'
require 'oddb/util/money'

module ODDB
  module Import
class Pharma24 < Import
  def initialize
    @count = 0
    @created_companies = 0
    @found = 0
    @host = 'http://www.apotheke-online-internet.de'
  end
  def import(agent, packages, opts={:all => false})
    agent.max_history = 1
    packages.collect! { |package| package.odba_id }
    while id = packages.shift
      update_package(agent, ODBA.cache.fetch(id), opts)
    end
    report
  end
  def import_company(data)
    name = company_name(data[:company])
    company = Business::Company.find_by_name(name) 
    if(company.nil?)
      @created_companies += 1
      company = Business::Company.new
      company.name.de = name
    end
    company
  end
  def import_size(data, package)
    part = package.parts.first || package.add_part(Drugs::Part.new)
    dose, size, multi = data[:size].to_s.split(/x/i, 3).reverse.compact
    unit = data[:unit].to_s
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
    if(unitname = data[:unitname])
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
  def get_alphabetical agent, fst, snd
    url = "#@host/#{fst}#{snd}.html"
    page = agent.get url
    data = extract_data page
    while (link = (page/'//a[@class="pageResults"]').last) \
            && link.innerText == '[n?chste?>>]'
      page = agent.get link.attributes['href']
      data.concat extract_data(page)
    end
    data
  end
  def extract_data page
    data = []
    (page/'tr[/td/h2/a]').each { |row| 
      link, = row/'h2/a'
      prod = {
        :name => utf8(link.innerText),
        :url  => link.attributes['href'],
      }
      details = row.next_sibling
      if price = (details/:strong).first
        prod.store :price_public, price.innerText.tr(',', '.').to_f
      end
      if prescription = (details/'td[text()="Abgabehinweis:"]').first
        prod.store :code_prescription, 
                   !!/Rezeptpflichtig/.match(prescription.next_sibling.innerText)
      end
      if content = (details/'td[text()="Packungsinhalt:"]').first
        size_str = content.next_sibling.innerText
        if match = /\s*(.*)\s+(\S+)\s+(\S+)\s*$/.match(size_str)
          size = utf8 match[1]
          unit = utf8 match[2]
          name = utf8 match[3]
          if size.empty?
            size, unit, name = unit, name, nil
          end
          prod.update :size => size, :unit => unit, :unitname => name
        end
      end
      if company = (details/'a[@class="liste"]').first
        prod.store :company, utf8(company.innerText)
      end
      data.push prod
    }
    data
  end
  def report
    lines = [
      sprintf("Checked %5i Packages", @count),
      sprintf("Updated %5i Packages", @found),
      sprintf("Created %5i Companies", @created_companies),
    ]
    lines
  end
  def search agent, term
    url = "#@host/advanced_search_result.php?keywords=#{term}"
    page = agent.get url
    extract_data page
  end
  def update_package agent, package, opts={}
    price = package.price(:public)
    resale = [ :pharma24,
               :csv_product_infos ].include?(package.data_origin(:price_public))
    needs_update = opts[:all] || price.nil? || resale
    if needs_update && (code = package.code(:cid, 'DE'))
      @count += 1
      data, = search agent, code.value
      if data
        @found += 1
        package.name.de = u(data[:name])
        presc = data[:code_prescription]
        if(code = package.code(:prescription))
          if(code.value != presc)
            code.value = presc
          end
        else
          package.add_code Util::Code.new(:prescription, presc, 'DE')
        end
        amount = data[:price_public]
        if(amount > 0)
          either = false
          if price.nil?
            package.add_price Util::Money.new(amount, :public, 'DE')
            either = true
          elsif resale
            if price != amount
              price.amount = amount
              either = true
            end
          end
          if either
            package.data_origins.store :price_public, :pharma24
          end
        end
        import_size data, package
        package.save
        if((product = package.product) && product.company.nil?)
          product.company = import_company(data)
          product.save
        end
      end
    end
  end
end
  end
end
