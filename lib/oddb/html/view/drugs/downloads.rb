require 'htmlgrid/errormessage'
require 'htmlgrid/labeltext'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/list'
require 'oddb/html/view/search'

module ODDB
  module Html
    module View
      module Drugs
class DownloadList < View::List
  include HtmlGrid::ErrorMessage
  COMPONENTS = {
    [0,0] => :name,
    [1,0] => :price_1,
    [2,0] => :price_12,
    [3,0] => :data_description,
    [4,0] => :example,
  }
  DEFAULT_HEAD_CLASS = 'groupheader'
  STRIPED_BG = true
  SORT_HEADER = false
  def init
    super
    error_message
  end
  def name model
    size = model.size
    unit = 'B'
    units = %w{KB MB GB TB}
    while size > 1024 && unit = units.shift
      size = (size / 1024.0).ceil
    end
    name = "#{model.name} (~ #{size} #{unit})"
    box = HtmlGrid::InputCheckbox.new "downloads[#{model.name}]",
                                      model, @session, self
    [box, name]
  end
  def price_1 model
    radio_price model, 1
  end
  def price_12 model
    radio_price model, 12
  end
  def radio_price model, months
    radio = HtmlGrid::InputRadio.new "months[#{model.name}]",
                                     model, @session, self
    radio.value = months
    selected = @session.user_input(:months) || {}
    radio.set_attribute 'checked', months == (selected[model.name] || 1).to_i
    [radio, "EUR %4.2f" % model.price(months)]
  end
end
class DownloadsComposite < HtmlGrid::DivForm
  COMPONENTS = {
    [0,0] => InlineSearch,
    [0,1] => "downloads",
    [0,2] => :download_info,
    [0,3] => DownloadList,
    [0,4] => :compression_label,
    [0,5] => :compression,
    [0,6] => :submit,
  }
  CSS_ID_MAP = [ 'result-search', 'title' ]
  CSS_MAP = { 1 => 'result', 2 => 'explain', 4 => 'padded',
              5 => 'padded', 6 => 'padded' }
  EVENT = :proceed_download
  SYMBOL_MAP = {
    :compression       => HtmlGrid::Select,
  }
  def compression_label model
    label = HtmlGrid::LabelText.new :compression_label, model, @session, self
    label.set_attribute 'for', :compression
    label
  end
  def download_info model
    link = HtmlGrid::Link.new(:download_info, model, @session, self)
    link.href = 'http://wiki.oddb.org/wiki.php?pagename=ODDB.Stammdaten'
    link
  end
end
class Downloads < Template
  CONTENT = DownloadsComposite
end
      end
    end
  end
end
