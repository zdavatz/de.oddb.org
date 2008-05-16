#!/usr/bin/env ruby
# Remote::Drugs::Package -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'oddb/util/money'
require 'oddb/util/multilingual'
require 'oddb/remote/object'
require 'oddb/remote/business/company'
require 'oddb/remote/drugs/active_agent'
require 'oddb/remote/drugs/atc'
require 'oddb/remote/drugs/dose'
require 'oddb/remote/drugs/galenic_form'
require 'oddb/remote/drugs/part'
require 'oddb/remote/drugs/unit'

module ODDB
  module Remote
    module Drugs
class Package < Remote::Object
  delegate :ddds, :ikscat, :sl_entry
  def initialize(source, remote, currency_rate, tax_factor=1.0)
    @tax_factor = tax_factor.to_f
    @currency_rate = currency_rate.to_f
    @cache = {}
    super(source, remote)
  end
  def active_agents
    @active_agents ||= @remote.active_agents.collect { |act|
      Remote::Drugs::ActiveAgent.new(@source, act)
    }
  end
  def atc
    @atc ||= Remote::Drugs::Atc.new(@source, @remote.atc_class)
  end
  def code(type, country='CH')
    case type
    when :ean
      @ean ||= Util::Code.new(:ean, @remote.barcode, 'CH')
    end
  end
  def company
    @company ||= Remote::Business::Company.new(@source, @remote.company)
  end
  def comparables
    local_comparables.concat @remote.comparables.collect { |pac|
      Package.new(@source, pac, @currency_rate, @tax_factor)
    }
  end
  def comparable_size
    @comparable_size ||= @remote.comparable_size
  end
  def ddds
    @ddds ||= galenic_forms.inject([]) { |memo, form|
      if(group = form.group)
        memo.concat atc.ddds(group.administration)
      end
      memo
    }
  end
  def dose_price(dose)
    if(price = price(:public))
      pdose = doses.first.want(dose.unit)
      Util::Money.new((dose / pdose).to_f * (price.to_f / size))
    end
  rescue StandardError
  end
  def galenic_forms
    @galenic_forms ||= @remote.galenic_forms.collect { |form|
      Remote::Drugs::GalenicForm.new(@source, form)
    }
  end
  def local_comparables
    comparables = []
    doses = active_agents.collect { |act| act.dose }
    if(doses.size == 1 \
       && (atc = ODDB::Drugs::Atc.find_by_code(self.atc.code)))
      descriptions = galenic_forms.collect { |form| form.description.de }
      groupnames = galenic_forms.collect { |form| form.groupname }
      range = (size*0.75)..(size*1.25)
      atc.products.each { |prod|
        prod.sequences.each { |seq|
          if(seq.doses == doses)
            descs = []
            names = []
            seq.galenic_forms.each { |form|
              descs.push form.description
              if grp = form.group
                names.push grp.name
              end
            }
            if(descs == descriptions || groupnames.all? { |name|
               names.any? { |other| other == name } })
              comparables.concat seq.packages.select { |pac|
                range.include?(pac.size)
              }
            end
          end
        }
      }
    end
    comparables
  end
  def name
    @name ||= Util::Multilingual.new(:de => @@iconv.iconv(@remote.name_base))
  end
  def parts
    @parts ||= @remote.parts.collect { |part| 
      Remote::Drugs::Part.new(@source, part)
    }
  end
  def price(type)
    case type
    when :public, :exfactory
      @cache.fetch(type) { @cache.store(type, remote_price(type)) }
    end
  end
  def remote_price(key)
    pr = @remote.send("price_#{key}").to_f * @currency_rate / @tax_factor
    Util::Money.new(pr.to_f) if(pr > 0)
  end
  def size
    @size ||= comparable_size.qty
  end
end
    end
  end
end
