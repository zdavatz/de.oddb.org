#!/usr/bin/env ruby
# Html::State::RegisterExport -- de.oddb.org -- 28.07.2008 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/util/need_all_input'
require 'oddb/html/view/register_export'

module ODDB
  module Html
    module State
class RegisterExport < Global
  include Util::NeedAllInput
  VIEW = View::RegisterExport
  def init
    super
    @query = @session.persistent_user_input(:query)
    @dstype = @session.persistent_user_input(:dstype) \
      || ODDB.config.default_dstype
  end
  def direct_event
    [:proceed_export, :query, @query, :dstype, @dstype]
  end
  def proceed_export
    query = @session.persistent_user_input(:query)
    dstype = @session.persistent_user_input(:dstype) \
      || ODDB.config.default_dstype
    filename = sprintf('%s_%s.csv', query.tr(' ', '-'), dstype)
    if @model.is_a?(ODDB::Business::Invoice) \
      && @model.items.any? { |item| item.text == filename }
      self
    else
      super
    end
  end
end
    end
  end
end
