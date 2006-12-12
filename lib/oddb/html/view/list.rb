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
  def query_key 
    :query
  end
  def sort_link(thkey, matrix, component)
    sortlink = HtmlGrid::Link.new(thkey, @model, @session, self)
    args = [
      query_key, model.query,
      'sortvalue', component.to_s,
    ]
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
      when "tt_code_festbetragsstufe"
        link.href = "http://www.die-gesundheitsreform.de/glossar/festbetraege.html"
      when "tt_code_zuzahlungsbefreit"
        link.value = link.href = "http://www.bkk.de/bkk/powerslave,id,1054,nodeid,.html"
        sortlink.dojo_title = [ title.strip, link ]
      when "tt_company"
        link.href = "http://www.die-gesundheitsreform.de/presse/pressethemen/avwg/pdf/liste_zuzahlungsbefreite_arzneimittel.pdf"
      when "tt_festbetrag"
        link.href = "http://www.dimdi.de/static/de/amg/fbag/index.htm"
      when "tt_price_public", "tt_price_difference"
        link.href = "ftp://ftp.dimdi.de/pub/amg/satzbeschr_011006.pdf"
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
