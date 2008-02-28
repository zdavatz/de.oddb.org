#!/usr/bin/env ruby
# Html::View::GoogleAds -- de.oddb.org -- 28.02.2008 -- hwyss@ywesee.com

require 'htmlgrid/component'

module ODDB
  module Html
    module View
class GoogleAds < HtmlGrid::Component
  def initialize(opts = {:channel => '2298340258', :width => 250, :height => 250})
    @channel = opts[:channel]
    @width = opts[:width]
    @height = opts[:height]
    @format = "#{@width}x#{@height}_as"
    super
  end
  def to_html(context)
    <<-EOS
<script type="text/javascript"><!--
google_ad_client = "pub-6948570700973491";
google_ad_width = "#{@width}";
google_ad_height = "#{@height}";
google_ad_format = "#{@format}";
google_ad_channel ="#{@channel}";
google_ad_type = "text_image";
google_color_border = "DBE1D6";
google_color_bg = "E6FFD6";
google_color_link = "003366";
google_color_url = "FF3300";
google_color_text = "003399";
//--></script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
    EOS
  end
end
    end
  end
end
