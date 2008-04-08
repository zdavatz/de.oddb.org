#!/usr/bin/env ruby
# Html::State::Drugs::Admin::Package -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/package'
require 'oddb/html/view/drugs/admin/package'
require 'oddb/import/pharmnet'

module ODDB
  module Html
    module State
      module Drugs
        module Admin
class Package < Drugs::Package
  VIEW = View::Drugs::Admin::Package
  def update
    mandatory = [ :name, :code_cid ]
    keys = [ :price_public, :price_festbetrag, :code_festbetragsstufe,
             :code_festbetragsgruppe, :code_zuzahlungsbefreit,
             :code_prescription, :unit, :size, :multi, :composition, 
             :quantity ]
    input = user_input(mandatory + keys, mandatory)
    email = @session.user.email
    others = ODDB::Drugs::Package.search_by_code(:type    => 'cid',
                                                 :value   => input[:code_cid],
                                                 :country => 'DE')
    others.delete(@model)
    unless others.empty?
      value = sprintf "'%i' (%s)", input[:code_cid], 
                      others.collect { |pac| pac.name.de }.join(', ')
      @errors.store(:code_cid, 
                    create_error(:e_duplicate_pzn, :code_cid, value))
    end
    input.each { |key, value|
      unless(@errors[key])
        set = case key
              when :name
                @model.name.de = value unless(@model.name.de == value)
              when :price_public, :price_festbetrag
                update_price(/price_(.*)/.match(key.to_s)[1].to_sym, value.to_f)
              when :code_cid, :code_festbetragsgruppe, :code_festbetragsstufe
                update_code(/code_(.*)/.match(key.to_s)[1].to_sym, value)
              when :code_zuzahlungsbefreit, :code_prescription
                update_code(/code_(.*)/.match(key.to_s)[1].to_sym, !!value)
              when :size
                update_parts(input)
              end
        unless(set.nil?)
          @model.data_origins.store key, email
        end
      end
    }
    @model.save
    self
  end
  def package
    if((code = @session.user_input(:pzn)) && @model.code(:cid, 'DE') == code)
      self
    else
      super
    end
  end
  private
  def update_code(type, value)
    if(code = @model.code(type))
      code.value = value unless(code == value)
    else
      @model.add_code Util::Code.new(type, value, 'DE')
    end
  end
  def update_parts(input)
    input[:size].each { |idx, size|
      part = @model.parts.at(idx.to_i)
      current = {}
      [:multi, :size, :unit, :quantity, :composition].each { |key|
        values = (input[key] ||= {})
        if((val = values[idx]) && !val.empty?)
          current.store(key, val)
        end
      }
      part.multi = current[:multi] && current[:multi].to_i
      part.size = current[:size]
      if(unitname = current[:unit])
        if(unit = ODDB::Drugs::Unit.find_by_name(unitname))
          part.unit = unit
        else
          key = :"unit[#{idx}]"
          @errors.store key, create_error(:e_unknown_unit, key, unitname)
        end
      else
        part.unit = nil
      end
      if(str = current[:quantity])
        part.quantity = ODDB::Drugs::Dose.new(*str.split(/(?=[^\d.,])/, 2))
      else
        part.quantity = nil
      end
      if(comp = current[:composition])
        part.composition = @model.compositions.at(comp.to_i)
      end
      part.save
    }
  end
  def update_price(type, amount)
    if(price = @model.price(type, 'DE'))
      price.amount = amount unless(price == amount)
    else
      @model.add_price ODDB::Util::Money.new(amount, type, 'DE')
    end
  end
end
        end
      end
    end
  end
end
