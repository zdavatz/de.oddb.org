#!/usr/bin/env ruby
# Html::State::Drugs::Package -- de.oddb.org -- 11.12.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module State
      module Drugs
class Package < Global
  VIEW = View::Drugs::Package
  def direct_event
    direct_event = [:package]
    if(code = @model.code(:cid, 'DE'))
      direct_event.push(code.value)
    end
    direct_event
  end
  def _package(code)
    if(@model.code(:cid, 'DE') == code)
      self
    else
      super
    end
  end
end
      end
    end
  end
end
