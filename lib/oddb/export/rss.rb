#!/usr/bin/env ruby
# Export::Rss -- de.oddb.org -- 10.12.2007 -- hwyss@ywesee.com

require 'oddb/util/feedback'
require 'oddb/export/l10n_sessions'

module ODDB
  module Export
    module Rss
class Exporter
  def initialize
    @rss_dir = File.join(ODDB.config.var, 'rss')
    @name = self.class.name[/[^:]+$/]
    @filename = @name.downcase + ".rss"
  end
  def export
    items = sorted_items
    return if(items.empty?)
    Export.l10n_sessions { |session|
      dir = File.join(@rss_dir, session.language)
      FileUtils.mkdir_p(dir)
      path = File.join(dir, @filename)
      tmp = File.join(dir, '.' << @filename)
      File.open(tmp, 'w') { |io|
        io.puts rss(items, session)
      }
      File.rename(tmp, path)
    }
  end
  def rss items, session
    require "oddb/html/view/rss/#{@name.downcase}"
    klass = Html::View::Rss.const_get @name
    view = klass.new(items, session, nil)
    view.to_html(CGI.new('html4'))
  end
end
class Feedback < Exporter
  def sorted_items
    Util::Feedback.newest(:all)
  end
end
    end
  end
end
