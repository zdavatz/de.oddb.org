#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/business/company'
require 'oddb/drugs/package'
require 'oddb/remote/drugs/package'
require 'oddb/html/state/global'
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
      rate = _remote_currency_rate(uri)
      package = Remote::Drugs::Package.new(source, pac, rate, 
                                           _remote_price_factor)
      result = Util::AnnotatedList.new(package.comparables) 
      result.origin = package
      result.query = package.atc.code
      CompareRemote.new(@session, result)
    end
  end
  def _compare(code)
    if(package = _package_by_code(code))
      result = Util::AnnotatedList.new(package.comparables) 
      result.origin = package
      result.query = code
      Compare.new(@session, result)
    end
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
  def _remote_price_factor
    1.0 / @session.lookandfeel.price_factor
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
  def _remote_currency_rate(uri)
    DRbObject.new(nil, uri).get_currency_rate("EUR")
  end
  def _search(query)
    result = Util::AnnotatedList.new
    result.query = query
    if(query.length < 3)
      result.error = :e_query_short
    else
      result.concat(ODDB::Drugs::Package.search_by_atc(query))
      if(result.empty?)
        companies = ODDB::Business::Company.search_by_name(query)
        companies.each { |comp|
          result.concat(comp.packages)
        }
      end
      if(result.empty?)
        result.concat(ODDB::Drugs::Package.search_by_substance(query))
      end
      if(result.empty?)
        result.concat(ODDB::Drugs::Package.search_by_name(query))
      end
    end
    if(@session.lookandfeel.enabled?(:remote_databases, false))
      result.concat(_search_remote(query))
    end
    Result.new(@session, result)
  end
  def _search_remote(query)
    result = []
    ODDB.config.remote_databases.each_with_index { |uri, source|
      begin
        remote = DRbObject.new(nil, uri)
        rate = _remote_currency_rate(uri)
        result.concat remote.remote_packages(query).collect { |pac|
          Remote::Drugs::Package.new(source, pac, rate, 
                                     _remote_price_factor)
        }
      rescue StandardError => e
        warn e.message
      end
    }
    result
  end
end
      end
    end
  end
end
