#!/usr/bin/env ruby
# Html::Util::Sort -- de.oddb.org -- 07.12.2006 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
module Sort
  def sort
    if(key = @session.user_input(:sortvalue))
      sort_by(key.to_sym)
    end
    self
  end
  def sort_by(key)
    sorter = sort_proc(key) || Proc.new { |pac| pac.send(key) || '' }
    @model = @model.sort_by(&sorter)
    if(@sortvalue == key)
      @reverse = !@reverse
      if(@reverse)
        @model.reverse!
      end
    else
      @reverse = false
      @sortvalue = key
    end
  end
  def sort_proc(key)
  end
end
    end
  end
end
