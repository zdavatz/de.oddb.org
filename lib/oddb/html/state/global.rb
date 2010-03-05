#!/usr/bin/env ruby
# Html::State::Drugs::Global -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/state/download'
require 'oddb/html/state/drugs/atc_browser'
require 'oddb/html/state/drugs/download_export'
require 'oddb/html/state/drugs/init'
require 'oddb/html/state/drugs/login'
require 'oddb/html/state/limit'
require 'oddb/html/state/register_download'
require 'oddb/html/state/register_export'
require 'oddb/html/state/register_poweruser'
require 'oddb/html/state/paypal/checkout'
require 'oddb/business/invoice'

module ODDB
  module Html
    module State
class Global < SBSM::State
  include PayPal::Checkout
  attr_reader :passed_turing_test
  LIMIT = false
  GLOBAL_MAP = {
    :atc_browser => Drugs::AtcBrowser,
    :downloads   => Drugs::Downloads,
    :login       => Drugs::Login,
  }
  def compare
    if(code = @session.user_input(:pzn))
      _compare(code)
    end
  end
  def _download(file)
    path = File.join ODDB.config.export_dir, file
    if File.exist?(path)
      Download.new(@session, path)
    elsif match = /(.+)_(.+).csv/.match(file)
      packages = _search_local match[1].tr('-', ' '), match[2]
      packages.filename = file
      Drugs::DownloadExport.new(@session, packages)
    end
  end
  def explain_ddd_price
    if((code = @session.user_input(:pzn)) \
       && (idx = @session.user_input(:offset)))
      _explain_ddd_price(code, idx.to_i)
    end
  end
  def explain_price
    if(code = @session.user_input(:pzn))
      _explain_price(code)
    end
  end
  def fachinfo
    if(uid = @session.user_input(:uid))
      _fachinfo(uid)
    end
  end
  def feedback
    if(code = @session.user_input(:pzn) || @session.user_input(:uid))
      _feedback(code)
    end
  end
  def home
    State::Drugs::Init.new @session, nil
  end
  def limited?
    self.class.const_get(:LIMIT)
  end
  def limit_state
    State::Limit.new(@session, nil)
  end
  def logout
    @session.logout
    home
  end
  def package
    if(code = @session.user_input(:pzn))
      _package(code)
    end
  end
  def package_infos
    if(code = @session.user_input(:pzn))
      _package_infos(code)
    end
  end
  def partitioned_keys(keys)
    keys.partition { |key|
      /^[a-z]$/.match(key)
    }
  end
  def patinfo
    if(uid = @session.user_input(:uid))
      _patinfo(uid)
    end
  end
  def proceed_download
    keys = [:downloads, :months, :compression]
    input = user_input keys, keys
    compression = input[:compression][/[^_]+$/]
    unless error?
      invoice = ODDB::Business::Invoice.new
      input[:downloads].each do |filename, status|
        if status == '1'
          months = input[:months][filename]
          prices = ODDB.config.prices["org.oddb.de.download.#{months}"] || {}
          price = prices[filename].to_f / months.to_i
          item = invoice.add :download, filename, months, '', price,
                             :compression => compression
          unless price > 0
            @errors.store "months[#{filename}]",
                          create_error(:e_empty_result, :months, '0')
          end
        end
      end
    end
    if error?
      self
    else
      State::RegisterDownload.new(@session, invoice)
    end
  end
  def proceed_export
    query = @session.persistent_user_input(:query)
    dstype = @session.persistent_user_input(:dstype) || ODDB.config.default_dstype
    result = _search_local(query, dstype)
    filename = sprintf('%s_%s.csv', query.tr(' ', '-'), dstype)
    if @session.allowed?('download', "#{ODDB.config.auth_domain}.#{filename}")
      result.filename = filename
      Drugs::DownloadExport.new @session, result
    else
      lines = result.size
      price = ODDB.config.prices["org.oddb.de.export.csv"].to_f
      unless(lines > 0 && price > 0)
        @errors.store :days, create_error(:e_empty_result, :query, query)
        self
      else
        invoice = ODDB::Business::Invoice.new
        item = invoice.add(:export, filename, lines, '', price)
        State::RegisterExport.new(@session, invoice)
      end
    end
  end
  def proceed_poweruser
    days = @session.user_input(:days).to_i
    total = ODDB.config.prices["org.oddb.de.view.#{days}"].to_f 
    unless(days > 0 && total > 0)
      @errors.store :days, create_error(:e_missing_days, :days, 0)
      self
    else
      invoice = ODDB::Business::Invoice.new
      item = invoice.add(:poweruser, "unlimited access", days, 
                         @session.lookandfeel.lookup(:days), total / days)
      State::RegisterPowerUser.new(@session, invoice)
    end
=begin
      if(usr = @session.user_input(:pointer))
        State::User::RenewPowerUser.new(@session, invoice)
      else
        State::User::RegisterPowerUser.new(@session, invoice)
      end
    end
=end
  end
  def product
    if(uid = @session.user_input(:uid))
      _product(uid)
    end
  end
  def products
    _products(@session.persistent_user_input(:range))
  end
  def remote_infos
    if(id = @session.user_input(:uid))
      _remote_infos(id)
    end
  end
  def sequence
    if(uid = @session.user_input(:uid))
      _sequence(uid)
    end
  end
  def navigation
    []
  end
  def method_missing(mth, *args)
    if(mth.to_s[0] == ?_)
      self
    else
      super
    end
  end
end
    end
  end
end
