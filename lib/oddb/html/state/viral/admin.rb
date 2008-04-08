#!/usr/bin/env ruby
# Html::State::Viral::Admin -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/admin/package'
require 'oddb/html/state/drugs/admin/product'
require 'oddb/html/state/drugs/admin/sequence'
require 'sbsm/viralstate'

module ODDB
  module Html
    module State
      module Viral
module Admin
	include SBSM::ViralState
  def limited?
    false
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
