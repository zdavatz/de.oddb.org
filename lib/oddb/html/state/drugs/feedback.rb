#!/usr/bin/env ruby
# Html::State::Drugs::Feedback -- de.oddb.org -- 06.12.2007 -- hwyss@ywesee.com

require 'delegate'
require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/feedback'
require 'oddb/util/feedback'

module ODDB
  module Html
    module State
      module Drugs
class Feedback < Global
  class Feedbackable < SimpleDelegator
    INDEX_STEP = 10
    attr_accessor :index
    attr_reader :current, :item
    def initialize(item)
      @item = item
      @index = 0
      @current = ODDB::Util::Feedback.new
      super
    end
    def created?
      @item.feedbacks.include? @current
    end
  end
  VIEW = View::Drugs::Feedback
  attr_reader :passed_turing_test
  def init
    @model = Feedbackable.new(@model)
    super
  end
  def direct_event
    direct_event = [:feedback]
    if(code = @model.code(:cid, 'DE'))
      direct_event.push([:pzn, code.value])
    end
    direct_event
  end
  def _feedback(code)
    if(@model.code(:cid, 'DE') == code)
      self
    else
      super
    end
  end
  def update
    mandatory = [:name, :email, :email_public, :item_good_experience, 
      :item_recommended, :item_good_impression, :item_helps]
    unless @passed_turing_test
      mandatory.push :captcha
    end
    keys = mandatory + [:message]
    hash = user_input(keys, mandatory)
    if(@passed_turing_test)
      # do nothing
    elsif((candidates = hash[:captcha]) && candidates.any? { |key, word| 
      @session.lookandfeel.captcha.valid_answer? key, word })
      @passed_turing_test = true
    else
      @errors.store(:captcha, create_error('e_failed_turing_test', 
        :captcha, nil))
    end
    unless(error?)
      feedback = @model.current
      info_key = (@model.created?) ? :feedback_changed : :feedback_saved
      
      hash.each { |key, value|
        writer = "#{key}="
        if(feedback.respond_to? writer)
          feedback.send writer, value
        end
      }
      feedback.time = Time.now
      feedback.item = @model.item
      feedback.save

      @session.update_feedback_rss_feed
      @infos = [info_key]
    end
    self
  end
end
      end
    end
  end
end
