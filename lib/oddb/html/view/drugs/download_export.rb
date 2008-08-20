#!/usr/bin/env ruby
# Html::View::DownloadExport -- de.oddb.org -- 29.07.2008 -- hwyss@ywesee.com

require 'htmlgrid/component'
require 'oddb/export/csv'

module ODDB
  module Html
    module View
      module Drugs
class DownloadExport < HtmlGrid::Component
  def http_headers
    {
      "Content-Type"        => "text/csv",
      "Cache-Control"       => "no-cache, max-age=3600, must-revalidate",
      "Content-Disposition" => "attachment; filename=#{@model.filename}",
      "Refresh"             => "0; URL=#{@lookandfeel._event_url(:home)}",
    }
  end
  def to_html(context)
    Export::Csv::Packages.export @model, @lookandfeel.csv_components, 
                                 @session.language
  end
end
      end
    end
  end
end
