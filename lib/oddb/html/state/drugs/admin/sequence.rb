#!/usr/bin/env ruby
# Html::State::Drugs::Admin::Sequence -- de.oddb.org -- 04.04.2008 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/admin/sequence'
require 'oddb/html/state/drugs/global'

module ODDB
  module Html
    module State
      module Drugs
        module Admin
class AjaxActiveAgents < Global
  VOLATILE = true
  VIEW = View::Drugs::Admin::ActiveAgents
end
class AjaxCompositions < Global
  VOLATILE = true
  VIEW = View::Drugs::Admin::Compositions
end
class Sequence < Global
  VIEW = View::Drugs::Admin::Sequence
  def ajax_create_active_agent
    check_model
    keys = [:uid, :composition]
    input = user_input(keys, keys)
    agents = []
    if(!error? \
       && (composition = @model.compositions.at(input[:composition].to_i)))
      agents = composition.active_agents
    end
    AjaxActiveAgents.new(@session, agents.dup.push(nil))
  end
  def ajax_create_composition
    check_model
    comps = @model.compositions.dup
    if(!error?)
      comp = ODDB::Drugs::Composition.new
      comp.active_agents.push nil
      comps.push comp
    end
    AjaxCompositions.new @session, comps
  end
  def ajax_delete_active_agent
    check_model
    keys = [:uid, :active_agent, :composition]
    input = user_input(keys, keys)
    agents = []
    if(!error? \
       && (composition = @model.compositions.at(input[:composition].to_i)))
      if(agent = composition.active_agents.at(input[:active_agent].to_i))
        agent.delete
        composition.remove_active_agent(agent)
        composition.save
      end
      agents = composition.active_agents
    end
    AjaxActiveAgents.new(@session, agents)
  end
  def ajax_delete_composition
    check_model
    keys = [:uid, :composition]
    input = user_input(keys, keys)
    agents = []
    if(!error? \
       && (composition = @model.compositions.at(input[:composition].to_i)))
      composition.delete
    end
    AjaxCompositions.new(@session, @model.compositions)
  end
  def check_model
    if(@model.uid.to_s != @session.user_input(:uid))
      @errors.store :uid, create_error(:e_state_expired, :uid, nil)
    end
  end
  def delete
    check_model
    unless error?
      prod = @model.product
      if(prod.is_a? Util::UnsavedHelper)
        prod = prod.delegate
      end
      @model.delete
      Product.new(@session, prod)
    end
  end
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
      document = imp.import_rtf(key, WWW::Mechanize.new, url, seq.product.name.de,
                                :reparse => true, :reload => true)
      parent = seq.send(key)
      parent.de = document
      parent.save
    end
  end
  def update
    check_model
    mandatory = [ :atc ]
    keys = [ :atc_name, :registration, :fachinfo_url, :patinfo_url,
      :galenic_form, :substance, :dose ]
    input = user_input(mandatory + keys, mandatory)
    unless /^EU/.match input[:registration].to_s
      others = ODDB::Drugs::Sequence.search_by_code(:type => 'registration',
                                                    :value => input[:registration],
                                                    :country => 'EU')
      others.delete(@model)
      unless others.empty?
        value = sprintf "'%s' (%s)", input[:registration],
                        others.collect { |seq|
                          seq.name.de || seq.product.name.de }.join(', ')
        @errors.store(:registration,
                      create_error(:e_duplicate_registration, :registration, value))
      end
    end
    _update input
  end
  def _update input
    email = @session.user.email
    if((prod = @model.product) && prod.is_a?(Util::UnsavedHelper))
      @model.product = prod.delegate
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
              when :fachinfo_url
                unless value == @model.fachinfo_url
                  _import_rtf(:fachinfo, @model, value)
                end
              when :patinfo_url
                unless value == @model.patinfo_url
                  _import_rtf(:patinfo, @model, value)
                end
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
    if(substances = input[:substance])
      substances.each { |cmp_idx, substances|
        doses = input[:dose][cmp_idx]
        gfstr = input[:galenic_form][cmp_idx]
        cmp_idx = cmp_idx.to_i
        comp = @model.compositions.at(cmp_idx)
        if(comp.nil?)
          comp = ODDB::Drugs::Composition.new
          comp.sequence = @model
        end
        if gfstr.to_s.empty?
          comp.galenic_form = nil
        elsif gform = ODDB::Drugs::GalenicForm.find_by_description(gfstr)
          comp.galenic_form = gform
        else 
          key = :"galenic_form[#{cmp_idx}]"
          @errors.store key, create_error(:e_unknown_galenic_form, key, gfstr)
        end
        substances.each { |sub_idx, sub|
          parts = doses[sub_idx].split(/\s*(?=[^\d.,])/, 2)
          sub_idx = sub_idx.to_i
          if(substance = ODDB::Drugs::Substance.find_by_name(sub))
            changed = false
            dose = ODDB::Drugs::Dose.new(*parts) unless parts.empty?
            agent = comp.active_agents.at(sub_idx)
            if(agent.nil?)
              agent = ODDB::Drugs::ActiveAgent.new substance, dose
              agent.composition = comp
              changed = true
            end
            if(agent.substance != substance)
              agent.substance = substance 
              changed = true
            end
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
        comp.save
      }
    end
    saved
  end
end
class NewSequence < Sequence
  def direct_event
    # disable redirector
  end
  def _update input
    unless @errors[:registration]
      super
      Sequence.new(@session, @model)
    end
  end
end
        end
      end
    end
  end
end
