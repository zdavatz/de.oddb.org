#!/usr/bin/env ruby
# Export::Xls -- de.oddb.org -- 13.03.2007 -- hwyss@ywesee.com

require 'fileutils'
require 'spreadsheet/excel'
require 'oddb/remote/drugs/package'
require 'oddb/util/comparison'

module ODDB
  module Export
    module Xls
class ComparisonDeCh
  @@iconv = Iconv.new('latin1//IGNORE//TRANSLIT', 'utf8')
  def export(drb_uri, io)
    write_xls(io, collect_comparables(drb_uri))
  end
  def adjust_price(price)
    price * currency_rate * tax_factor
  end
  def collect_comparables(drb_uri)
    data = []
    DRb::DRbObject.new(nil, drb_uri).remote_each_package { |remote|
      package = Remote::Drugs::Package.new(drb_uri, remote,
                                           1.0 / currency_rate, 
                                           tax_factor)
      if(package.price(:public) \
         && (comparable = package.local_comparables.select { |pac|
            pac.price(:public)
          }.sort_by { |pac|
            pac.price(:public)
          }.first))
        data.push [comparable, package]
      end
      nil # don't return data from the block across drb
    }
    data
  end
  def collect_cell(local, remote, format = "%s (%s)", &block)
    lval = block.call(local) rescue StandardError
    rval = block.call(remote) rescue StandardError
    @@iconv.iconv(lval == rval ? lval : sprintf(format, lval, rval))
  end
  def currency_rate
    @currency_rate ||= Currency.rate('EUR', 'CHF')
  end
  def tax_factor
    1.076 / 1.19
  end
  def write_row(worksheet, idx, local, remote)
    comparison = Util::Comparison.new(local, remote)
    rprice = remote.price(:public)
    worksheet.write idx, 0, [
      collect_cell(local, remote) { |x| 
        x.name.de || x.product.name.de },
      collect_cell(local, remote) { |x| x.comparable_size.to_s },
      adjust_price(local.price(:public)).to_s,
      collect_cell(local, remote) { |x| x.company.name.de },
      local.code(:cid).to_s,
      remote.code(:ean).to_s,
      collect_cell(local, remote) { |x| 
        x.galenic_forms.first.description.de },
      collect_cell(local, remote) { |x| 
        x.active_agents.first.dose.to_s },
      collect_cell(local, remote) { |x| 
        x.active_agents.first.substance.name.de },
      remote.atc.code,
      remote.ikscat,
      remote.code(:zuzahlungsbefreit) ? 'SL' : '',
      sprintf("%+4.2f", adjust_price(comparison.absolute)),
      sprintf("%+4.2f%%", comparison.difference),
      sprintf("%4.2f%", comparison.factor),
    ]
  end
  def write_xls(io, data)
    workbook = Spreadsheet::Excel.new(io)
    worksheet = workbook.add_worksheet('Preisvergleich')
    fmt_title = Format.new(:bold => true)
    workbook.add_format(fmt_title)
    worksheet.write 0, 0, [
      "Name DE (Name CH)",
      "Pkg Grösse DE (Pkg Grösse CH)",
      "AVP inkl. Mwst in CHF nach Abzug und Zuschlag",
      "Hersteller DE (Hersteller CH)",
      "PZN", "EAN",
      "Gal Form DE (gal. Form CH)",
      "Stärke (Schreibweise CH)",
      "Wirkstoff (Schreibweise CH)",
      "ATC-Code", "Abgabekategorie CH", "SL Schweiz",
      "Preisunterschied pro Tablette inkl. Mwst. in CHF",
      "Preisunterschied in %",
      "Packungsäquivalenzfaktor",
    ].collect { |str| @@iconv.iconv str }, fmt_title
    data.sort_by { |local, remote| 
      local.name.de || local.product.name.de
    }.each_with_index { |(local, remote), idx|
      write_row(worksheet, idx.next, local, remote)
    }
    workbook.close
  end
end
    end
  end
end
