#!/usr/bin/env ruby
# Html::View::List -- de.oddb.org -- 12.12.2006 -- hwyss@ywesee.com

require 'htmlgrid/list'

module ODDB
  module Html
    module View
class List < HtmlGrid::List
  BACKGROUND_ROW = 'bg'
  BACKGROUND_SUFFIX = ''
  LEGACY_INTERFACE = false
  SORT_DEFAULT = nil
  def query_args
    []
  end
  def query_key 
    :query
  end
  def sort_link(thkey, matrix, component)
    sortlink = HtmlGrid::Link.new(thkey, @model, @session, self)
    args = [ query_key, model.query ]
    args.concat query_args
    args.push('sortvalue', component.to_s)
    sortlink.href = @lookandfeel._event_url(@session.event, args)
    sortlink.css_class = css_head_map[matrix]
    sortlink.css_id = thkey
    titlekey = thkey.sub(/^th/, "tt")
    if(title = @lookandfeel.lookup(titlekey))
      ## Inefficient - if there are performance problems, remove the
      #  next two lines and set dojo_title only where necessary
      link = HtmlGrid::Link.new(titlekey, @model, @session, self)
      sortlink.dojo_title = link
      # TODO: make the hrefs dynamic (latest update)
      case titlekey
      when "tt_active_agents"
        link.value = @lookandfeel.lookup(:tt_active_agents_link)
        link.href = "ftp://ftp.dimdi.de/pub/amg/darform_011006.txt"
        sortlink.dojo_title = [ title, link ]
      when "tt_atc"
        link.href = "http://www.whocc.no/atcddd/atcsystem.html"
      when "tt_company"
        link.href = "http://www.gkv.info/gkv/index.php?id=445"
      when "tt_price_festbetrag"
        link.href = "http://www.dimdi.de/static/de/amg/fbag/index.htm"
      when "tt_price_public", "tt_price_difference"
        link.href = "ftp://ftp.dimdi.de/pub/amg/satzbeschr_010108.pdf"
      when "tt_price_exfactory"
        link.href = "http://wiki.oddb.org/uploads/Main/Aenderung_der_AMPVo_per_1.1.2004_-_632.pdf"
      else
        sortlink.dojo_title = title
      end
    end
    sortlink
  end
end
    end
  end
end
