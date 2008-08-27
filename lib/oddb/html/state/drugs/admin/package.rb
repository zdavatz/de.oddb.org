#!/usr/bin/env ruby
# Html::State::Drugs::Admin::Package -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/package'
require 'oddb/html/view/drugs/admin/package'
require 'oddb/import/pharmnet'
require 'oddb/util/code'

module ODDB
  module Html
    module State
      module Drugs
        module Admin
class AjaxParts < Global
  VOLATILE = true
  VIEW = View::Drugs::Admin::Parts
end
class Package < Drugs::Package
  VIEW = View::Drugs::Admin::Package
  def ajax_create_part
    check_model
    parts = @model.parts.dup
    if(!error?)
      part = ODDB::Drugs::Part.new
      part.package = Util::UnsavedHelper.new(@model)
      parts.push part
    end
    AjaxParts.new @session, parts
  end
  def ajax_delete_part
    check_model
    keys = [:code_cid, :part]
    input = user_input(keys, keys)
    agents = []
    if(!error? \
       && (part = @model.parts.at(input[:part].to_i)))
      part.delete
    end
    AjaxParts.new(@session, @model.parts)
  end
  def check_model
    if(@model.code(:cid, 'DE') != @session.user_input(:code_cid))
      @errors.store :code_cid, create_error(:e_state_expired, :code_cid, nil)
    end
  end
  def delete
    check_model
    unless error?
      seq = @model.sequence
      if(seq.is_a? Util::UnsavedHelper)
        seq = seq.delegate
      end
      @model.delete
      Sequence.new(@session, seq)
    end
  end
  def update
    mandatory = [ :name, :code_cid ]
    keys = [ :price_exfactory, :price_public, :price_festbetrag,
             :code_festbetragsstufe, :code_festbetragsgruppe,
             :code_zuzahlungsbefreit, :code_prescription, :unit, :sequence,
             :size, :multi, :composition, :quantity ]
    input = user_input(mandatory + keys, mandatory)
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
    _update input
  end
  def _update input
    email = @session.user.email
    input.each { |key, value|
      unless(@errors[key])
        set = case key
              when :name
                @model.name.de = value unless(@model.name.de == value)
              when :price_public, :price_festbetrag, :price_exfactory
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
    if((uid = input[:sequence]) \
       && (seq = ODDB::Drugs::Sequence.find_by_uid(uid)) \
       && @model.sequence != seq)
      @model.sequence = seq
      @model.parts.each_with_index { |part, idx| 
        part.composition = seq.compositions[idx]
        part.save
      }
    elsif((seq = @model.sequence) && seq.is_a?(Util::UnsavedHelper))
      @model.sequence = seq.delegate
    end
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
      @model.add_code ODDB::Util::Code.new(type, value, 'DE')
    end
  end
  def update_parts(input)
    if(sizes = input[:size])
      sizes.each { |idx, size|
        part = @model.parts.at(idx.to_i)
        part ||= ODDB::Drugs::Part.new
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
          part.quantity = ODDB::Drugs::Dose.new(*str.split(/\s*(?=[^\d.,])/, 2))
        else
          part.quantity = nil
        end
        if(comp = current[:composition])
          part.composition = @model.compositions.at(comp.to_i)
        end
        part.package = @model unless(part.package == @model)
        part.save
      }
    end
  end
  def update_price(type, amount)
    if price = @model.price(type, 'DE')
      if amount > 0
        price.amount = amount unless(price == amount)
      else
        @model.remove_price price
      end
    elsif amount > 0
      @model.add_price ODDB::Util::Money.new(amount, type, 'DE')
    end
  end
end
class NewPackage < Package
  def direct_event
    # disable redirector
  end
  def _update input
    unless @errors[:code_cid]
      super 
      Package.new(@session, @model)
    end
  end
end
        end
      end
    end
  end
end
