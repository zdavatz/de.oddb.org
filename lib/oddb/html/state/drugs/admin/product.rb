#!/usr/bin/env ruby
# Html::State::Drugs::Admin::Product -- de.oddb.org -- 04.04.2008 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/admin/product'
require 'oddb/html/state/drugs/global'

module ODDB
  module Html
    module State
      module Drugs
        module Admin
class Product < Global
  VIEW = View::Drugs::Admin::Product
  def direct_event
    direct_event = [:product]
    if(uid = @model.uid)
      direct_event.push([:uid, uid])
    end
    direct_event
  end
  def update
    value = user_input :company
    error_check_and_store(:company, value, [:company])
    unless error?
      set = if(company = ODDB::Business::Company.find_by_name(value))
              @model.company = company
            else
              @errors.store :company, create_error(:e_unknown_company,
                                                   :company, value)
              nil
            end
      unless(set.nil?)
        @model.data_origins.store :company, @session.user.email
      end
    end
    @model.save
    self
  end
  def product
    if((uid = @session.user_input(:uid)) && @model.uid.to_s == uid)
      self
    else
      super
    end
  end
end
        end
      end
    end
  end
end
