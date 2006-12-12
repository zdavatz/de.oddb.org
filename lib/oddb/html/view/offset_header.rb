#!/usr/bin/env ruby
# Html::View::OffsetHeader -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com

module ODDB
  module Html
    module View
module OffsetHeader
  def compose_header(offset=[0,0])
    offset = super
    model = @session.state.model
    items = model.size
    step = @session.pagelength
    if(items > step)
      current_offset = @session.user_input(:offset).to_i
      0.step(items - 1, step) { |idx|
        link = HtmlGrid::Link.new(:page, @model, @session, self)
        link.value = sprintf("%i - %i", idx.next, 
                             [idx + step, items].min)
        unless(idx == current_offset)
          link.href = @lookandfeel._event_url(@session.event,
            [query_key, model.query, 'offset', idx])
        end
        @grid.add(link, *offset)
      }
      @grid.set_colspan(offset.at(0), offset.at(1), full_colspan)
      @grid.add_attribute('id', 'offsetheader', *offset)
      resolve_offset(offset, self::class::OFFSET_STEP)
    else
      offset
    end
  end
end
    end
  end
end
