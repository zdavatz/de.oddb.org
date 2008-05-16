#!/usr/bin/env ruby
# Remote::Drugs::Part -- de.oddb.org -- 16.05.2008 -- hwyss@ywesee.com

require 'oddb/remote/object'

module ODDB
  module Remote
    module Drugs
class Part < Remote::Object
  delegate :multi, :size
  def comparable_size
    @comparable_size ||= @remote.comparable_size
  end
  def quantity
    nil
  end
  def unit
    @unit ||= begin
                cstr = if comform = @remote.commercial_form
                         comform.de
                       else
                         comparable_size.unit
                       end
                @unit = Remote::Drugs::Unit.new(@source, @@iconv.iconv(cstr))
              end
  end
end
    end
  end
end
