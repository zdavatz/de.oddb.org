#!/usr/bin/env ruby
# Html::View::Drugs::Feedback -- de.oddb.org -- 06.12.2007 -- hwyss@ywesee.com

require 'htmlgrid/errormessage'
require 'htmlgrid/form'
require 'htmlgrid/infomessage'
require 'htmlgrid/inputradio'
require 'htmlgrid/labeltext'
require 'htmlgrid/textarea'
require 'oddb/html/view/drugs/package'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/list'
require 'oddb/html/view/search'
require 'oddb/html/view/snapback'

module ODDB
  module Html
    module View
      module Drugs
class FeedbackList < List
  class << self
    def boolean ypos, key
      components.update( [0, ypos] => key ) 
      define_method(key) { |model| boolean model.send(key) }
    end
    def components
      @components ||= {}
    end
  end
  COLSPAN_MAP = { [0,0] => 2 }
  COMPONENTS = {
    [0,0] => :name,
    [0,1] => :email,
    [0,2] => :message,
  }
  boolean 3, :item_good_experience
  boolean 4, :item_recommended
  boolean 5, :item_good_impression
  boolean 6, :item_helps
  CSS_MAP = {
    [0,2] => 'top',
  }
  LABELS = true
  LOOKANDFEEL_MAP = {
    :message => :feedback,
  }
  OFFSET_STEP = [0,7]
  OMIT_HEADER = true
  def init
    components.update self.class.components
    super
  end
  def boolean(bool)
    div = HtmlGrid::Div.new(bool, @session, self)
    css = 'square '
    if(bool)
      div.value = '+'
      css << 'plus'
    else
      div.value = '-'
      css << 'minus'
    end
    div.css_class = css
    div.label = true
    div
  end
  def email(model)
    value = HtmlGrid::Value.new(:email, model, @session, self)
    if(!model.email_public)
      value.value = @lookandfeel.lookup(:email_not_public)
    end
    value
  end
  def name(model)
    @lookandfeel.lookup(:feedback_by, model.name, 
                        model.time.strftime("%A, %d. %B %Y - %H:%M"))
  end
end
class FeedbackForm < HtmlGrid::Form
  class << self
    def radio ypos, key
      key = key.to_sym
      truekey = "#{key}_true"
      falsekey = "#{key}_false"
      components.update( [0, ypos] => key, 
                         [1, ypos, 0] => truekey.to_sym,
                         [2, ypos, 1] => truekey,
                         [1, ypos + 1, 0] => falsekey.to_sym,
                         [2, ypos + 1, 1] => falsekey)
      css_map.update( [1, ypos] => 'radio', [1, ypos + 1] => 'radio')
      symbol_map.store(key, HtmlGrid::LabelText)
      define_method(truekey) { |model| radio_true(key) }
      define_method(falsekey) { |model| radio_false(key) }
    end
    def components
      @components ||= {}
    end
    def css_map
      @css_map ||= {}
    end
    def symbol_map
      @symbol_map ||= {}
    end
  end
  COMPONENTS = {
    [0,0] => :name,
    [0,1] => :email,
    [0,4] => :message,
  }
  radio 2, :email_public
  radio 5, :item_good_experience
  radio 7, :item_recommended
  radio 9, :item_good_impression
  radio 11, :item_helps
  include HtmlGrid::ErrorMessage
  include HtmlGrid::InfoMessage
  CSS_MAP = { 
    [0,4] => 'top', 
  }
  COLSPAN_MAP = {
    [1,0] => 2,
    [1,1] => 2,
    [1,4] => 2,
    [1,13] => 2,
  }
  CSS_CLASS = 'composite top'
  LABELS = true
  LOOKANDFEEL_MAP = {
    :message => :feedback_message,
  }
  EVENT = :update
  LEGACY_INTERFACE = false
  SYMBOL_MAP = {
    :email_public => HtmlGrid::LabelText,
  }
  def init
    components.update self.class.components
    symbol_map.update self.class.symbol_map
    css_map.update self.class.css_map
    if(@session.passed_turing_test?)
      components.update([1,13]=>:submit)
    else
      components.update([0,13]=>:captcha, [1,14]=>:captcha_image, [1,15]=>:submit)
      colspan_map.update([1,14]=>2, [1,15]=>2)
    end
    super
    error_message
    info_message
  end
  def challenge
    @challenge ||= @lookandfeel.generate_challenge
  end
  def captcha(model)
    name = "captcha[#{challenge.id}]"
    HtmlGrid::InputText.new(name, model, @session, self)
  end
  def captcha_image(model)
    img = HtmlGrid::Image.new(:file, challenge, @session, self)
    img.attributes["src"] = File.join('', 'captcha', challenge.file)
    img
  end
  def email_public_false(model)
    radio_false(:email_public)
  end
  def email_public_true(model)
    radio_true(:email_public)
  end
  def radio_true(true_key)
    radio = HtmlGrid::InputRadio.new(true_key, model, @session, self)
    if(model.send(true_key) || @session.user_input(true_key))
      radio.set_attribute('checked', true)
    end
    radio.value = '1'
    radio.label = false
    radio
  end
  def radio_false(false_key)
    radio = HtmlGrid::InputRadio.new(false_key, model, @session, self)
    if(model.send(false_key).eql?(false) \
       || @session.user_input(false_key).eql?(false))
      radio.set_attribute('checked', true)
    end
    radio.value = '0'
    radio.label = false
    radio
  end
  def message(model)
    input = HtmlGrid::Textarea.new(:message, model, @session, self)
    input.set_attribute('wrap', true)
    js = "if(this.value.length > 400) { (this.value = this.value.substr(0,400))}" 
    input.set_attribute('onKeypress', js)
    input.label = true
    input
  end
end
class FeedbackComposite < HtmlGrid::DivComposite
  include Snapback
  include Drugs::PackageMethods
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :feedback_for,
    [0,3] => :feedbacks,
    [0,4] => :feedback_form,
  }
  CSS_ID_MAP = [ 'snapback', 'result-search', 'title', 'feedbacks' ]
  CSS_MAP = { 
    0 => 'before-searchbar', 
    3 => 'mezzo righthand', 
    4 => 'mezzo lefthand', 
  }
  def feedbacks(model)
    FeedbackList.new(model.feedbacks.reverse, @session, self)
  end
  def feedback_for(model)
    if size = size(model)
      @lookandfeel.lookup(:feedback_for, model.name, size)
    else
      @lookandfeel.lookup(:feedback_for_sequence, model.name)
    end
  end
  def feedback_form(model)
    FeedbackForm.new(model.current, @session, self)
  end
end
class Feedback < Template
  CONTENT = FeedbackComposite
  def _title
    super[0..-2].push(@model.name.send(@session.language))
  end
end
      end
    end
  end
end
