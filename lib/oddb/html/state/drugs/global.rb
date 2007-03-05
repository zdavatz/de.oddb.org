#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/business/company'
require 'oddb/drugs/package'
require 'oddb/remote/drugs/package'
require 'oddb/html/state/global'
require 'oddb/html/state/drugs/ajax/package_infos'
require 'oddb/html/state/drugs/compare'
require 'oddb/html/state/drugs/init'
require 'oddb/html/state/drugs/package'
require 'oddb/html/state/drugs/products'
require 'oddb/html/state/drugs/result'
require 'oddb/html/util/annotated_list'
require 'ostruct'

module ODDB
  module Html
    module State
      module Drugs
class Global < State::Global
  EVENT_MAP = {
    :home => Drugs::Init,
  }
  def compare_remote
    id = @session.user_input(:uid)
    source, ref = id.split('.', 2)
    uri = ODDB.config.remote_databases.at(source.to_i)
    if(pac = DRbObject._load(Marshal.dump([uri, ref])))
      rate = _remote(uri) { |remote| remote.get_currency_rate("EUR") }
      package = Remote::Drugs::Package.new(source, pac, rate, 
                                           _tax_factor)
      result = Util::AnnotatedList.new(package.comparables)
      result.origin = package
      result.query = package.atc.code
      CompareRemote.new(@session, result)
    end
  end
  def _compare(code)
    if(package = _package_by_code(code))
      result = Util::AnnotatedList.new(package.comparables) 
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
  def navigation
    [:products].concat(super)
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
  def _products(query)
    result = Util::AnnotatedList.new
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
            @session.persistent_user_input(:dstype))
  end
  def _search(query, dstype)
    result = Util::AnnotatedList.new
    result.query = query
    result.dstype = dstype || 'compare'
    if(query.length < 3)
      result.error = :e_query_short
    else
      case dstype
      when 'tradename'
        _search_by(:name, query, result)
        _search_by(:product, query, result) if result.empty?
      when 'substance'
        _search_by(:substance, query, result)
      else
        _search_by(:atc, query, result)
        _search_by(:company, query, result) if result.empty?
        _search_by(:substance, query, result) if result.empty?
        _complete(_search_by(:name, query, result)) if result.empty?
        _complete(_search_by(:product, query, result)) if result.empty?
      end
    end
    if(@session.lookandfeel.enabled?(:remote_databases, false))
      result.concat(_search_remote(query))
    end
    Result.new(@session, result)
  end
  def _search_by(key, query, result)
    result.concat ODDB::Drugs::Package.send("search_by_#{key}", query)
  end
  def _search_remote(query)
    _remote_packages { |remote| remote.remote_packages(query) }
  end
end
      end
    end
  end
end
