#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/business/company'
require 'oddb/drugs/package'
require 'oddb/html/state/global'
require 'oddb/html/state/drugs/init'
require 'oddb/html/state/drugs/result'
require 'ostruct'

module ODDB
  module Html
    module State
      module Drugs
class Global < State::Global
  EVENT_MAP = {
    :home => Drugs::Init,
  }
  def _search(query)
    result = OpenStruct.new
    result.query = query
    companies = ODDB::Business::Company.search_by_name(query)
    packages = companies.inject([]) { |memo, comp|
      memo.concat(comp.packages)
    }
    if(packages.empty?)
      packages = ODDB::Drugs::Package.search_by_name(query)
    end
    result.packages = packages
    Result.new(@session, result)
  end
  def navigation
    [:home]
  end
end
      end
    end
  end
end
