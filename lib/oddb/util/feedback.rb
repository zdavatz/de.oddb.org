#!/usr/bin/env ruby
# Util::Feedback -- de.oddb.org -- 06.12.2007 -- hwyss@ywesee.com

require 'oddb/model'

module ODDB
  module Util
class Feedback < Model
  belongs_to :item
  attr_accessor :name, :email, :message, :email_public, :item_good_experience,
    :item_recommended, :item_good_impression, :item_helps, :time
end
  end
end
