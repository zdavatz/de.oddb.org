#!/usr/bin/env ruby
# Html::State::Drugs::Admin::Sequence -- de.oddb.org -- 04.04.2008 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/admin/sequence'
require 'oddb/html/state/drugs/global'

module ODDB
  module Html
    module State
      module Drugs
        module Admin
class Sequence < Global
  VIEW = View::Drugs::Admin::Sequence
  def direct_event
    direct_event = [:sequence]
    if(uid = @model.uid)
      direct_event.push([:uid, uid])
    end
    direct_event
  end
  def _import_rtf(key, seq, url)
    if(url && !url.empty?)
      imp = Import::PharmNet::Import.new
      document = imp.import_rtf(key, WWW::Mechanize.new, url, seq.name.de)
      seq.send(key).de = document
    end
  end
  def update
    mandatory = [ :atc ]
    keys = [ :atc_name, :registration, :fi_url, :pi_url, :substance, :dose ]
    input = user_input(mandatory + keys, mandatory)
    email = @session.user.email
    others = ODDB::Drugs::Sequence.search_by_code(:type => 'registration',
                                                  :value => input[:registration],
                                                  :country => 'EU')
    others.delete(@model)
    unless others.empty?
      value = sprintf "'%s' (%s)", input[:registration], 
                      others.collect { |seq| seq.name.de }.join(', ')
      @errors.store(:registration, 
                    create_error(:e_duplicate_registration, :registration, value))
    end
    input.each { |key, value|
      unless(@errors[key])
        set = case key
              when :atc
                if(value.empty?)
                  warn "empty atc"
                elsif(atc = ODDB::Drugs::Atc.find_by_code(value))
                  @model.atc = atc
                elsif((name = input[:atc_name]) && !name.empty?)
                  atc = ODDB::Drugs::Atc.new value
                  atc.name.de = name
                  atc.save
                  @model.atc = atc
                else
                  @errors.store :atc, create_error(:e_unknown_atc, :atc, value)
                  nil
                end
              when :fi_url
                _import_rtf(:fachinfo, @model, value)
              when :pi_url
                _import_rtf(:patinfo, @model, value)
              when :registration
                if(value.empty?)
                  @model.remove_code(@model.registration)
                elsif(code = @model.registration)
                  code.value = value unless code == value
                else
                  @model.add_code ODDB::Util::Code.new(:registration, value, 'EU')
                end
              when :substance
                update_compositions(input)
              end
        unless(set.nil?)
          @model.data_origins.store key, email
        end
      end
    }
    @model.save
    self
  end
  def sequence
    if((uid = @session.user_input(:uid)) && @model.uid.to_s == uid)
      self
    else
      super
    end
  end
  private
  def update_compositions(input)
    saved = nil
    input[:substance].each { |cmp_idx, substances|
      doses = input[:dose][cmp_idx]
      cmp_idx = cmp_idx.to_i
      if comp = @model.compositions.at(cmp_idx)
        substances.each { |sub_idx, sub|
          parts = doses[sub_idx].split(/(?=[^\d.,])/, 2)
          sub_idx = sub_idx.to_i
          if(substance = ODDB::Drugs::Substance.find_by_name(sub))
            agent = comp.active_agents.at(sub_idx)
            changed = false
            if(agent.substance != substance)
              agent.substance = substance 
              changed = true
            end
            dose = ODDB::Drugs::Dose.new(*parts)
            if(agent.dose != dose)
              agent.dose = dose
              changed = true
            end
            if changed
              saved = true
              agent.save 
            end
          else
            key = :"substance[#{cmp_idx}][#{sub_idx}]"
            @errors.store key, create_error(:e_unknown_substance, key, sub)
          end
        }
      end
    }
    saved
  end
end
        end
      end
    end
  end
end
