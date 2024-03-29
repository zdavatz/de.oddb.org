#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/business/company'
require 'oddb/drugs/package'
require 'oddb/remote/drugs/package'
require 'oddb/html/state/global'
require 'oddb/html/state/drugs/ajax/explain_price'
require 'oddb/html/state/drugs/ajax/explain_ddd_price'
require 'oddb/html/state/drugs/ajax/package_infos'
require 'oddb/html/state/drugs/ajax/remote_infos'
require 'oddb/html/state/drugs/atc_guidelines'
require 'oddb/html/state/drugs/compare'
require 'oddb/html/state/drugs/downloads'
require 'oddb/html/state/drugs/init'
require 'oddb/html/state/drugs/login'
require 'oddb/html/state/drugs/fachinfo'
require 'oddb/html/state/drugs/feedback'
require 'oddb/html/state/drugs/package'
require 'oddb/html/state/drugs/patinfo'
require 'oddb/html/state/drugs/products'
require 'oddb/html/state/drugs/result'
require 'oddb/html/util/know_it_all'
require 'oddb/util/annotated_list'
require 'ostruct'

module ODDB
  module Html
    module State
      module Drugs
module Events
  def compare_remote
    if((uid = @session.user_input(:uid)) \
       && (package = _remote_package(uid)))
      result = ODDB::Util::AnnotatedList.new(package.comparables)
      result.origin = package
      result.query = uid
      CompareRemote.new(@session, result)
    end
  end
  def _compare(code)
    if(package = _package_by_code(code))
      result = ODDB::Util::AnnotatedList.new(package.comparables)
      if(@session.lookandfeel.enabled?(:remote_databases, false))
        result.concat(_remote_comparables(package))
      end
      result.origin = package
      result.query = code
      Compare.new(@session, result)
    end
  end
  def _complete(result)
    atcs = {}
    result.dup.each { |package|
      if((atc = package.atc) && !atcs[atc])
        atcs.store(atc, true)
        result.concat(atc.packages)
      end
    }
    result.uniq!
  end
  def ddd
    if((code = @session.user_input(:code)) \
       && (atc = ODDB::Drugs::Atc.find_by_code(code)))
      AtcGuidelines.new(@session, atc)
    end
  end
  def _explain_ddd_price(code, idx)
    if((package = _package_by_code(code)) \
       && (ddd = package.ddds.at(idx)))
      Ajax::ExplainDddPrice.new(@session, 
                                :ddd => ddd, :package => package)
    end
  end
  def _explain_price(code)
    if(package = _package_by_code(code))
      Ajax::ExplainPrice.new(@session, package.price(:public))
    end
  end
  def _fachinfo(uid)
    if(sequence = ODDB::Drugs::Sequence.find_by_uid(uid))
      Fachinfo.new(@session, sequence)
    end
  end
  def _feedback(code)
    if(item = _package_by_code(code) || _sequence_by_code(code))
      Feedback.new(@session, item)
    end
  end
  def limited?(*args)
    super && !@session.allowed?('view', ODDB.config.auth_domain)
  end
  def navigation
    [:products, :atc_browser, :downloads].concat(super)
  end
  def _package(code)
    if(package = _package_by_code(code))
      Package.new(@session, package)
    end
  end
  def _package_by_code(code)
    ODDB::Drugs::Package.find_by_code(:type => 'cid', 
                                      :value   => code, 
                                      :country => 'DE')
  end
  def _package_infos(code)
    if(package = _package_by_code(code))
      Ajax::PackageInfos.new(@session, package)
    end
  end
  def _patinfo(uid)
    if(sequence = ODDB::Drugs::Sequence.find_by_uid(uid))
      Patinfo.new(@session, sequence)
    end
  end
  def _products(query)
    result = ODDB::Util::AnnotatedList.new
    result.query = query
    if(query)
      if(query == '0-9')
        alpha, others = partitioned_keys(ODDB::Drugs::Product.name_keys(1))
        others.each { |key|
          result.concat(ODDB::Drugs::Product.search_by_name(key))
        }
      else
        result.concat(ODDB::Drugs::Product.search_by_name(query.downcase))
      end
    end
    Products.new(@session, result)
  end
  def _remote(uri, &block)
    block.call DRbObject.new(nil, uri)
  rescue StandardError => e
    warn e.message 
  end
  def _remote_comparables(package)
    if(atc = package.atc)
      _remote_packages { |remote| 
        remote.remote_comparables(ODBA::DRbWrapper.new(package))
      }
    end
  end
  def _remote_infos(uid)
    if(pac = _remote_package(uid))
      Ajax::RemoteInfos.new(@session, pac)
    end
  end
  def _remote_package(id)
    source, ref = id.split('.', 2)
    uri = ODDB.config.remote_databases.at(source.to_i)
    if(pac = DRbObject._load(Marshal.dump([uri, ref])))
      rate = _remote(uri) { |remote| 
        remote.get_currency_rate("EUR") }
      Remote::Drugs::Package.new(source, pac, rate, _tax_factor)
    end
  end
  def _remote_packages(&block)
    result = []
    ODDB.config.remote_databases.each_with_index { |uri, source|
      _remote(uri) { |remote|
        rate = remote.get_currency_rate("EUR")
        block.call(remote).each { |pac|
          result.push Remote::Drugs::Package.new(source, pac, rate, 
                                                 _tax_factor)
        }
      }
    }
    result
  end
  def _tax_factor
    @session.lookandfeel.tax_factor
  end
  def search
    _search(@session.persistent_user_input(:query),
            @session.persistent_user_input(:dstype) || ODDB.config.default_dstype)
  end
  def _search(query, dstype)
    result = _search_local(query, dstype)
    if(@session.lookandfeel.enabled?(:remote_databases, false))
      result.concat(_search_remote(query))
    end
    Result.new(@session, result)
  end
  def _search_append_products(query, result)
    table = {}
    result.each do |package|
      table.store package.product.uid, true
    end
    products = ODDB::Drugs::Product.search_by_name(query)
    products.reject! do |prod| table[prod.uid] end
    products.collect! do |prod|
      Util::KnowItAll.new prod, :active_agents => [], :parts => [], :ddds => []
    end
    result.concat products
  end
  def _search_append_sequences(query, result)
    table = {}
    result.each do |package|
      table.store package.sequence.uid, true
    end
    sequences = ODDB::Drugs::Sequence.search_by_product(query)
    sequences.reject! do |seq| table[seq.uid] end
    sequences.collect! do |seq|
      parts = seq.compositions.collect do |comp|
        Util::KnowItAll.new nil, :unit => comp.galenic_form
      end
      Util::KnowItAll.new seq, :active_agents => [], :parts => parts,
                               :ddds => [], :sequence => seq
    end
    result.concat sequences
  end
  def _search_by(key, query, result)
    result.concat ODDB::Drugs::Package.send("search_by_#{key}", query)
  end
  def _search_local(query, dstype)
    result = ODDB::Util::AnnotatedList.new
    result.query = query
    result.dstype = dstype || ODDB.config.default_dstype
    if(query.length < 3)
      result.error = :e_query_short
    else
      case dstype
      when 'company'
        _search_by(:company, query, result)
      when 'substance'
        _search_by(:substance, query, result)
      when 'compare'
        _search_by(:atc, query, result)
        _search_by(:company, query, result) if result.empty?
        _search_by(:substance, query, result) if result.empty?
        _complete(_search_by(:name, query, result)) if result.empty?
        _complete(_search_by(:product, query, result)) if result.empty?
      when 'indication'
        seqs = ODDB::Drugs::Sequence.search_by_fachinfo_indications_de(query)
        seqs.each { |seq| result.concat seq.packages }
      else
        _search_by(:name, query, result)
        _search_by(:product, query, result) if result.empty?
        _search_append_sequences(query, result)
        _search_append_products(query, result)
      end
    end
    result
  end
  def _search_remote(query)
    _remote_packages { |remote| remote.remote_packages(query) }
  end
  def _sequence_by_code(code)
    ODDB::Drugs::Sequence.find_by_uid(code)
  end
end
class Global < State::Global
  class << self
    def transparent_login(*events)
      events.each { |event|
        define_method(event) {
          state = trigger(:login)
          state.desired_input = @session.valid_input.dup
          state
        }
      }
    end
  end
  include Events
  transparent_login :_product, :_sequence
end
      end
    end
  end
end
