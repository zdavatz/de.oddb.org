#!/usr/bin/env ruby
# Import::Csv::ProductInfos -- de.oddb.org -- 13.02.2007 -- hwyss@ywesee.com

require 'csv'
require 'net/pop'
require 'oddb/business/company'
require 'oddb/drugs/active_agent'
require 'oddb/drugs/composition'
require 'oddb/drugs/dose'
require 'oddb/drugs/package'
require 'oddb/drugs/part'
require 'oddb/drugs/substance'
require 'oddb/drugs/unit'
require 'oddb/import/import'
require 'oddb/import/pharmnet'
require 'oddb/util/code'
require 'oddb/util/money'
require 'oddb/config'
require 'fileutils'
require 'rmail'
require 'zip/zip'

module ODDB
  module Import
    module Csv
class ProductInfos < Import
  def ProductInfos.download_latest(&block)
    c = ODDB.config.credentials["product_infos"]
    sources = []
    Net::POP3.start(c["pop_server"], c["pop_port"] || 110, 
                    c["pop_user"], c["pop_pass"]) { |pop|
      pop.each_mail { |mail|
        source = mail.pop
        ## work around a bug in RMail::Parser that cannot deal with
        ## RFC-2822-compliant CRLF..
        time = Time.now
        name = sprintf("%s.%s.%s", c["pop_user"], 
                       time.strftime("%Y%m%d%H%M%S"), time.usec)
        dir = File.join(ODDB.config.var, 'mail')
        FileUtils.mkdir_p(dir)
        path = File.join(dir, name)
        File.open(path, 'w') { |fh| fh.puts(source) }
        mail.delete
        source.gsub!(/\r\n/, "\n")
        sources.push source
      }
    }
    sources.each { |source|
      extract_message(RMail::Parser.read(source), &block)
    }
    sources.size
  rescue StandardError => e
		warn e.message
  end
  def ProductInfos.extract_message(message, &block)
    if(message.multipart?)
      message.each_part { |part|
        extract_message(part, &block)
      }
    elsif(/application.zip/.match message.header.content_type('text/plain'))
      path = File.join(ODDB.config.var, 'product_infos.zip')
      File.open(path, 'w') { |fh| fh << message.decode }
      open(path, &block)
    end
  end
  def ProductInfos.open(path = File.join(ODDB.config.var, 'product_infos.zip'),
                        &block)
    Zip::ZipFile.foreach(path) { |zh|
      block.call(zh.get_input_stream) 
    }       
  end
  def initialize
    super
    @count = 0
    @created = 0
    @created_companies = 0
    @created_galenic_forms = 0
    @created_packages = 0
    @created_products = 0
    @created_sequences = 0
    @created_substances = 0
    @found = 0
    @date = Date.today
  end
  def cell(row, idx)
    if((str = row.at(idx)) && !str.to_s.empty?)
      u(@@iconv.iconv(str.to_s))
    end
  end
  def create_package(sequence, pzn, name, row)
    @created_packages += 1
    package = Drugs::Package.new
    package.add_code(Util::Code.new(:cid, pzn, 'DE', @date))
    part = Drugs::Part.new
    part.composition = sequence.compositions.first
    part.package = package
    package.sequence = sequence
    import_known(package, name, row)
    package.save
  end
  def create_product(pzn, prodname, name, data, row)
    @created_products += 1
    product = Drugs::Product.new
    product.name.de = prodname
    sequence = create_sequence(product, pzn, name, data, row) 
    product.save
    sequence
  end
  def create_sequence(product, pzn, name, data, row)
    @created_sequences += 1
    sequence = Drugs::Sequence.new
    composition = Drugs::Composition.new
    data[:composition].each { |act|
      substance = import_substance(act[:substance])
      active_agent = Drugs::ActiveAgent.new(substance, act[:dose])
      composition.add_active_agent(active_agent)
    }
    composition.galenic_form = import_galenic_form(cell(row, 5))
    composition.save
    sequence.add_composition(composition)
    sequence.product = product
    create_package(sequence, pzn, name, row)
    sequence.save
  end
  def identify_details(result, pzn, name, row)
    compname = name.dup << ' ' << cell(row, 3)
    data = @pharmnet.suitable_data([compname, cell(row, 5), cell(row, 9)], 
                                   result, :cutoff => 0.12, :keep_dose => true)
    if(data.empty?)
      data = @pharmnet.suitable_data([compname, nil, cell(row, 9)], 
                                     result, :cutoff => 0.12, :keep_dose => true)
    end
    if data.size > 1
      ODDB.logger.error('ProductInfos') { 
        sprintf("Error: Found %i possible Details for %s (%s)\n%s", data.size, 
                name, pzn, data.pretty_inspect)
      }
      nil
    else
      data.first
    end
  end
  def import(io, opts = {:import_unknown => false, :import_known => true})
    skip = @skip_rows
    begin
      CSV::IOReader.new(io, ';').each { |row|
        if(skip > 0)
          skip -= 1
        else
          import_row(row, opts)
        end
      }
    rescue CSV::IllegalFormatError
      # Zip::ZipInputStream returns a superfluous empty String at EOF, which
      # upsets CSV::IOReader. Ignore this error and send a report of newly
      # created products anyway.
    end
    report
  end
  def import_row(row, opts = {:import_unknown => false, :import_known => true})
    pzn = u(row.at(0).to_i.to_s)
    name = cell(row, 1).gsub(/[A-Z .&+-]+/) { |part| 
      capitalize_all(part) }
    @count += 1
    if(opts[:import_known] \
       && (package = Drugs::Package.find_by_code(:type    => 'cid',
                                                 :value   => pzn,
                                                 :country => 'DE')))
      import_known(package, name, row)
    elsif(opts[:import_unknown] \
          && (!opts[:pattern] || opts[:pattern].match(name)))
      opts[:agent] ||= WWW::Mechanize.new
      import_unknown(opts[:agent], pzn, name, row)
    end
  end
  def import_company(row)
    name = company_name(row.at(9))
    company = Business::Company.find_by_name(name) 
    if(company.nil?)
      @created_companies += 1
      company = Business::Company.new
      company.name.de = name
    end
    company
  end
  def import_dose(row, package)
    if(package.size == 1 && (sequence = package.sequence) \
       && sequence.compositions.size == 1 \
       && (match = cell(row, 1).match(/\d+([.,]\d+)?/)))
      dose = match[1] ? match[0].gsub(',', '.').to_f : match[0].to_i
      if(sequence.active_agents.size == 1)
        agent = sequence.active_agents.first
        size = row.at(3).to_i
        if(agent.dose.qty == size * dose)
          update_sequence(package, 
                          Drugs::Dose.new(dose, agent.dose.unit))
        end
      end
    end
  end
  def import_galenic_form(desc)
    galform = Drugs::GalenicForm.find_by_description(desc)
    if(galform.nil?)
      @created_galenic_forms += 1
      galform = Drugs::GalenicForm.new
      galform.description.de = desc
      galform.save
    end
    galform
  end
  def import_known(package, name, row)
    @found += 1
    modified = false
    if(package.name != name)
      modified = true
      package.name.de = name
    end
    presc = row.at(2) == 'Rezeptpflichtig'
    if(code = package.code(:prescription))
      if(code.value != presc)
        modified = true
        code.value = presc
      end
    else
      modified = true
      package.add_code Util::Code.new(:prescription, presc, 'DE')
    end
    amount = cell(row, 6).to_f
    if(amount > 0)
      price = package.price(:public)
      either = false
      if price.nil?
        package.add_price Util::Money.new(amount, :public, 'DE')
        either = true
      elsif package.data_origin(:price_public) == :csv_product_infos
        if price != amount
          price.amount = amount
          either = true
        end
      end
      if either
        package.data_origins.store :price_public, :csv_product_infos
        modified = true
      end
    end
    import_dose(row, package) && modified = true
    package.save if(modified)
    import_size(row, package)
    product = package.product
    unless(product.company)
      product.company = import_company(row)
      product.save
    end
  end
  def import_size(row, package)
    if(part = package.parts.first)
      dose, size, multi = row.at(3).to_s.split(/x/i, 3).reverse.compact
      unit = row.at(4).to_s
      if(unit != 'St')
        part.quantity = Drugs::Dose.new(dose, unit)
      elsif(multi.nil?)
        multi = size
        size = dose
      end
      multi = multi.to_i
      size = size.to_i
      part.multi = (multi > 0) ? multi : nil
      part.size = (size > 0) ? size : nil
      if(unitname = cell(row, 5))
        unit = Drugs::Unit.find_by_name(unitname)
        unless(unit)
          unit = Drugs::Unit.new  
          unit.name.de = unitname
          unit.save
        end
        part.unit = unit
      end
      part.save
    end
  end
  def import_substance(name)
    sub = Drugs::Substance.find_by_name(name)
    if(sub.nil?)
      @created_substances += 1
      sub = Drugs::Substance.new
      sub.name.de = name
      sub.save
    end
    sub
  end
  def import_unknown(agent, pzn, name, row)
    @pharmnet ||= PharmNet::Import.new
    result = @pharmnet.get_search_result(agent, name, nil, 
                                         { :info_unrestricted => true, 
                                           :retries           => 1})
    return unless result
    result.delete_if { |data| data[:composition].nil? }
    data = identify_details(result, pzn, name, row)
    return unless data && data[:composition]
    prod = cell(row, 1)[/^([A-Z]{2,}\s)+/]
    comp = cell(row, 9)[/^([\d.]\s|[0-9A-Z])+/]
    prodname = "#{prod} #{comp}"
    ODDB.logger.debug('ProductInfos') { 
      sprintf("Creating new Package from\n%s", data.pretty_inspect)
    }
    products = Drugs::Product.search_by_name(prodname)
    sequence = nil
    if(products.empty?)
      sequence = create_product(pzn, prodname, name, data, row)
    elsif(products.size == 1)
      sequence = update_product(products.first, pzn, name, data, row)
    else 
      return
    end
    opts = {:replace => true}
    @pharmnet.assign_info(:fachinfo, agent, data, sequence, opts)
    @pharmnet.assign_info(:patinfo, agent, data, sequence, opts)
    sequence.product
  end
  def update_sequence(package, dose)
    sequence = package.sequence
    existing = package.product.sequences.find { |seq|
      seq.doses == [dose]
    }
    if(existing)
      package.sequence = existing
      package.save
      if(sequence.packages.empty?)
        sequence.delete
      end
    elsif(sequence.packages.size == 1)
      agent = sequence.active_agents.first
      agent.dose = dose
      agent.save
    else
      @created += 1
      substance = sequence.active_agents.first.substance
      seq = Drugs::Sequence.new
      comp = Drugs::Composition.new
      agent = Drugs::ActiveAgent.new(substance, dose)
      comp.add_active_agent(agent)
      comp.save
      seq.add_composition(comp)
      seq.product = sequence.product
      package.sequence = seq
      package.save
    end
  end
  def update_product(product, pzn, name, data, row)
    doses = data[:composition].collect { |act| act[:dose] }.sort
    sequence = product.sequences.find { |seq| doses == seq.doses.sort }
    if(sequence.nil?)
      sequence = create_sequence(product, pzn, name, data, row) 
    else
      create_package(sequence, pzn, name, row)
    end
    sequence
  end
  def report
    lines = [
      sprintf("Checked %5i Lines", @count),
      sprintf("Updated %5i Packages", @found),
      sprintf("Created %5i Sequences", @created),
      sprintf("Created %5i Companies", @created_companies),
      sprintf("Created %5i Products", @created_products),
      sprintf("Created %5i Sequences", @created_sequences),
      sprintf("Created %5i Galenic Forms", @created_galenic_forms),
      sprintf("Created %5i Substances", @created_substances),
      sprintf("Created %5i Packages", @created_packages),
    ]
    if @pharmnet
      lines.concat [
        "",
        "Errors: #{@pharmnet.errors.size}",
      ].concat(@pharmnet.errors.collect { |name, message, line, link| 
        sprintf "%s: %s (%s) -> http://gripsdb.dimdi.de%s", 
                name, message, line, link
      })
    end
    lines
  end
end
    end
  end
end
