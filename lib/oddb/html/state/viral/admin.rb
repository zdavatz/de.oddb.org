#!/usr/bin/env ruby
# Html::State::Viral::Admin -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/admin/package'
require 'oddb/html/state/drugs/admin/product'
require 'oddb/html/state/drugs/admin/sequence'
require 'oddb/html/util/unsaved_helper'
require 'sbsm/viralstate'

module ODDB
  module Html
    module State
      module Viral
module Admin
	include SBSM::ViralState
  def atc_assign
    email = @session.user.email
    newstate = search
    code = user_input(:code)
    model = newstate.model
    if(atc = ODDB::Drugs::Atc.find_by_code(code))
      packages = model.find { |list| list.atc.nil? }
      packages.each { |package| 
        if((seq = package.sequence) && seq.atc.nil?)
          seq.atc = atc
          seq.data_origins[:atc] = email
          seq.save
        end
      }
      ## do a completely new search to get everything sorted properly
      model.query = nil
      newstate = newstate.search
    else
      @errors.store :atc_assign, create_error(:e_unknown_atc, :atc_assign, code)
    end
    newstate
  end
  def limited?
    false
  end
  def new_package
    if((uid = @session.user_input(:uid)) \
       && (sequence = ODDB::Drugs::Sequence.find_by_uid(uid)))
      pac = ODDB::Drugs::Package.new
      pac.sequence = Util::UnsavedHelper.new(sequence)
      part = ODDB::Drugs::Part.new
      part.package = Util::UnsavedHelper.new(pac)
      pac.parts.push part
      Drugs::Admin::NewPackage.new(@session, pac)
    end
  end
  def new_sequence
    if((uid = @session.user_input(:uid)) \
       && (product = ODDB::Drugs::Product.find_by_uid(uid)))
      seq = ODDB::Drugs::Sequence.new
      seq.product = Util::UnsavedHelper.new(product)
      Drugs::Admin::NewSequence.new(@session, seq)
    end
  end
  def _package(code)
    if(package = _package_by_code(code))
      State::Drugs::Admin::Package.new(@session, package)
    end
  end
  def _product(uid)
    if(product = ODDB::Drugs::Product.find_by_uid(uid))
      State::Drugs::Admin::Product.new(@session, product)
    end
  end
  def _sequence(uid)
    if(sequence = ODDB::Drugs::Sequence.find_by_uid(uid))
      State::Drugs::Admin::Sequence.new(@session, sequence)
    end
  end
end
      end
    end
  end
end
