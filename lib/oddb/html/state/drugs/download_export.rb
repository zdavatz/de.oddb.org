#!/usr/bin/env ruby
# Html::State::Drugs::DownloadExport -- de.oddb.org -- 28.07.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/download_export'

module ODDB
  module Html
    module State
      module Drugs
class DownloadExport < Global
  VIEW = View::Drugs::DownloadExport
  VOLATILE = true
end
      end
    end
  end
end
