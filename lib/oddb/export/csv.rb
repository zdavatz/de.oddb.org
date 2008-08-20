#!/usr/bin/env ruby
# Export::Csv -- de.oddb.org -- 22.07.2008 -- hwyss@ywesee.com

require 'fastercsv'

module ODDB
  module Export
    module Csv
class Packages
  def self.export(packages, components, language = :de)
    atcs = partition packages
    FasterCSV.generate { |csv|
      atcs.each { |list|
        csv << atc_line(list.atc, language)
        list.each { |pac|
          csv << package_line(pac, components, language)
        }
      }
    }
  end
  def self.atc_line(atc, language)
    if atc
      result = [atc.code]
      if name = atc.name
        result.push name.send(language)
      end
      result
    else
      ['ATC-Code nicht bekannt']
    end
  end
  def self.active_agents(package, lang)
    package.active_agents.join('|')
  end
  def self.ddd_prices(package, language)
    ddds = []
    package.ddds.each_with_index { |ddd, idx|
      ddds.push sprintf("%s (%s)", package.dose_price(ddd.dose), 
                        ddd.administration)
    }
    ddds.join '|'
  end
  def self.package_line(package, components, language)
    components.collect { |key|
      value = if respond_to?(key)
                self.send key, package, language
              elsif package.respond_to?(key)
                package.send key
              end
      case value
      when Util::Multilingual
        value.send language
      else
        value
      end
    }
  end
  def self.partition(packages)
    atcs = {}
    packages.each { |package|
      code = (atc = package.atc) ? atc.code : 'X'
      (atcs[code] ||= Util::AnnotatedList.new(:atc => atc)).push(package)
    }
    atcs.sort.collect { |code, packages|
      packages
    }
  end
  def self.price_exfactory(package, lang)
    package.price(:exfactory)
  end
  def self.price_festbetrag(package, lang)
    package.price(:festbetrag)
  end
  def self.price_public(package, lang)
    package.price(:public)
  end
  def self.product(package, language)
    (product = package.product) && product.name
  end
  def self.size(package, language)
    package.parts.collect { |part| part.to_s(language) }.join('+')
  end
end
    end
  end
end
