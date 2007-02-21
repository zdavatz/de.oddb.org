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
require 'oddb/remote/drugs/unit'

module ODDB
  module Remote
    module Drugs
class Package < Remote::Object
  def initialize(source, remote, currency_rate)
    @currency_rate = currency_rate.to_f
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
  def company
    @company ||= Remote::Business::Company.new(@source, @remote.company)
  end
  def comparables
    comparables = @remote.comparables.collect { |pac|
      Package.new(@source, pac, @currency_rate)
    }
    doses = active_agents.collect { |act| act.dose }
    if(doses.size == 1 \
       && (atc = ODDB::Drugs::Atc.find_by_code(self.atc.code)))
      description = galenic_form.description.de
      groupname = galenic_form.groupname
      range = (size*0.75)..(size*1.25)
      atc.products.each { |prod|
        prod.sequences.each { |seq|
          if(seq.doses == doses)
            form = seq.galenic_form.first
            group = form.group
            if(form.description == description \
               || (group && group.name == groupname))
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
  def code(type, country='DE')
    #case type
    #when :cid
    #  @pzn ||= Util::Code.new(:cid, @remote.ikskey, 'CH')
    #end
  end
  def _comparable_size
    @comparable_size ||= @remote.comparable_size
  end
  def galenic_form
    @galenic_form ||= Remote::Drugs::GalenicForm.new(@source, 
                        @remote.galenic_form)
  end
  def name
    @name ||= Util::Multilingual.new(:de => @@iconv.iconv(@remote.name_base))
  end
  def parts
    [self]
  end
  def price(type)
    case type
    when :public
      @price_public or begin
        price = @remote.price_public.to_f * @currency_rate
        @price_public = Util::Money.new(price/100.0) if(price > 0)
      end
    end
  end
  def quantity
    nil
  end
  def size
    @size ||= _comparable_size.qty
  end
  def unit
    @unit ||= Remote::Drugs::Unit.new(@source, 
                @@iconv.iconv(@remote.comform || _comparable_size.unit))
  end
end
    end
  end
end
