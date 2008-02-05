#!/usr/bin/env ruby
# Html::State::Viral::Admin -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/state/drugs/admin/package'
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
end
      end
    end
  end
end
