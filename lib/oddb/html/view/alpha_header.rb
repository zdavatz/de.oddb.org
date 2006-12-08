#!/usr/bin/env ruby
# Html::View::AlphaHeader -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com 

module ODDB
  module Html
    module View
module AlphaHeader
  EMPTY_LIST_KEY = :choose_range
  def compose_header(offset=[0,0])
    offset = super
    current_range = @model.query
    @session.state.intervals.each { |range|
      link = HtmlGrid::Link.new(:range, @model, @session, self)
      link.value = range
      unless(range == current_range)
        link.href = @lookandfeel._event_url(@session.direct_event,
          'range' => range)
      end
      @grid.add(link, *offset)
    }
    @grid.set_colspan(offset.at(0), offset.at(1), full_colspan)
    @grid.add_attribute('id', 'alphaheader', *offset)
    resolve_offset(offset, self::class::OFFSET_STEP)
  end
end
    end
  end
end
