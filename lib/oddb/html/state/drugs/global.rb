#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/business/company'
require 'oddb/drugs/package'
require 'oddb/html/state/global'
require 'oddb/html/state/drugs/init'
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
