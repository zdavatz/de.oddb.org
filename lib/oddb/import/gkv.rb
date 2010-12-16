#!/usr/bin/env ruby
# Import::Gkv -- de.oddb.org -- 17.08.2009 -- hwyss@ywesee.com

require 'rpdf2txt/default_handler'
require 'rpdf2txt/parser'
require 'mechanize'
require 'open-uri'
require 'oddb/import/importer'
require 'oddb/util/money'
require 'drb'

module ODDB
  module Import
class GkvHandler < Rpdf2txt::SimpleHandler
  attr_reader :pairs
  def initialize callback
    @callback = callback
    @rows = []
    reset
  end
  def reset
    @current_line = ''
  end
  def send_flowing_data(data)
    @current_line << data
  end
  def send_line_break
    data = @current_line.strip.split /\s{3,}/
    if /^\d{6,}$/.match(data[1].to_s)
      ## ensure consistent row-length, so we can append additional substances
      #  to the tail
      data[9] ||= nil
      @rows.push data
    else
      @rows.push :doubtful
    end
    reset
  end
  def send_page
    @callback.call @rows
    @rows = []
    reset
  end
end
class Gkv < Importer
  def initialize
    super
    @assigned_companies = 0
    @assigned_equivalences = 0
    @confirmed_pzns = {}
    @count = 0
    @created = 0
    @created_companies = 0
    @created_products = 0
    @created_sequences = 0
    @created_substances = 0
    @deleted = 0
    @existing = 0
    @existing_companies = 0
    @existing_substances = 0
    @doubtful_pzns = []
    @missingname_uids = []  # UIDs of products which has no name
  end
  def download_latest(url, opts={}, &block)
    opts = {:date => Date.today}.merge(opts)
    file = File.basename(url)
    pdf_dir = File.join(ODDB.config.var, 'pdf/gkv')
    FileUtils.mkdir_p(pdf_dir)
    dest = File.join(pdf_dir, file)
    archive = File.join(ODDB.config.var, 'pdf/gkv',
                sprintf("%s-%s", opts[:date].strftime("%Y.%m.%d"), file))
    content = open(url).read
    if(!File.exist?(dest) || content.size != File.size(dest))
      open(archive, 'w') { |local|
        local << content
      }
      open(archive, 'r', &block)
      open(dest, 'w') { |local|
        local << content
      }
    end
  rescue StandardError => error
    ODDB.logger.error('Gkv') { error.message }
  end
  def latest_url agent, opts={}
    host = 'https://www.gkv-spitzenverband.de'
    url = '/Befreiungsliste_Arzneimittel_Versicherte.gkvnet'
    page = agent.get host + url
    file_base_name = "Zuzahlungsbefreit"
    link = (page/'a').map{|tag| tag['href']}.grep(/#{file_base_name}/)
    if link.length == 1 and link.to_s.match(/\.pdf/)
      return host + link.to_s
    else
      return nil
    end
  end
  def import fh, opts={}
    parser = Rpdf2txt::Parser.new(fh.read, 'utf8')
    handler = GkvHandler.new method(:process_page)
    parser.extract_text handler
    postprocess
    report
  end
  def import_row(row)
    if row == :doubtful
      @doubtful_pzns.push @created_pzn if @created_pzn
      @created_pzn = nil
      return
    end
    @count += 1
    package = import_package(row)
    return if package.nil?
    @confirmed_pzns.store(package.code(:cid).value, true)
    if(code = package.code(:zuzahlungsbefreit))
      if(code.value)
        @existing += 1
      else
        @created += 1
      end
      code.value = true
    else
      @created += 1
      code = Util::Code.new(:zuzahlungsbefreit, true, 'DE')
      package.add_code(code)
    end
    sequence = package.sequence
    product = sequence.product if sequence
    part = package.parts.first
    mnum, qnum = row.at(6).to_s.split('X')
    if(qnum.nil?)
      mnum, qnum = qnum, mnum
    end
    sunit = row.at(7)
    if(sunit == "ml")
      dose = Drugs::Dose.new(qnum, sunit)
      if(part.quantity != dose || part.size != mnum)
        part.quantity = dose
        part.size = mnum
        part.unit = nil
        save part
      end
    else
      unit = Drugs::Unit.find_by_name(row.at(8))
      changed = false
      if(qnum && part.size != qnum)
        part.size = qnum
        changed = true
      end
      if(unit && part.unit != unit)
        part.unit = unit
        changed = true
      end
      save(part) if changed
    end
    if(product && (company = import_company(row)) && product.company != company)
      product.company = company
      save product
    end
    if sequence
      import_active_agent(sequence, row, 3)
      import_active_agent(sequence, row, 10)
      import_active_agent(sequence, row, 13)
    end
    save package
  end
  def import_active_agent(sequence, row, offset)
    name = row.at(offset)
    sane = sanitize_substance_name(name)
    composition = sequence.compositions.first
    dose = Drugs::Dose.new(row.at(offset + 1),
                           row.at(offset + 2))
    ## check for slightly different names
    if(composition \
      && (agent = composition.active_agents.find { |act|
        act.substance.name.all.any? { |sub|
          sane == sanitize_substance_name(sub)
        }
      }))
      agent.dose = dose
      save agent
      substance = agent.substance
      if(substance.name != name)
        substance.name.add_synonym(name) && save(substance)
      end
    elsif(substance = import_substance(name))
      ## for now: don't expect multiple compositions
      if(composition.nil?)
        composition = Drugs::Composition.new
        composition.sequence = sequence
        save composition
        save sequence
      end
      candidate_names = [ name[/^\S+/], name[/^[^-]+/] ]
      composition.active_agents.each { |agent|
        other = agent.substance.name.de
        if other == name[0,other.length]
          candidate_names.push other
        end
      }
      candidate_names.uniq!
      agent = nil
      if(agent = composition.active_agent(substance))
        agent.dose = dose
        save agent
      elsif(candidate_names.any? { |name|
        agent = composition.active_agent(name) } )
        previous = agent.chemical_equivalence
        if(previous && previous.substance == substance)
          previous.dose = dose
          save previous
        else
          previous.delete if(previous)
          chemical = Drugs::ActiveAgent.new(substance, dose)
          save chemical
          agent.chemical_equivalence = chemical
          save agent
        end
      else
        agent = Drugs::ActiveAgent.new(substance, dose)
        agent.composition = composition
      end
    end
  end
  def import_company(row)
    if name = row.at(2)
      cname = company_name(name)
      company = Business::Company.find_by_name(cname)
      if(company)
        @existing_companies += 1
      else
        @created_companies += 1
        company = Business::Company.new
        company.name.de = cname
        save company
      end
      company
    end
  end
  def import_galenic_form(row)
    Drugs::GalenicForm.find_by_description(:value   => row.at(7),
                                           :type    => "galenic_form",
                                           :country => 'DE')
  end
  def import_package(row)
    pzn = row.at(1).to_i
    return if(pzn == 0)
    pzn = u(pzn.to_s)
    package = Drugs::Package.find_by_code(:type => 'cid',
                                          :value => pzn,
                                          :country => 'DE')
    @created_pzn = nil
    if(package.nil?)
      @created_pzn = pzn
      package = Drugs::Package.new
      package.add_code(Util::Code.new(:cid, pzn, 'DE'))
      part = Drugs::Part.new
      part.package = package
      save part
      product = import_product(package, row)
      package.sequence = import_sequence(product, package, row)
      # save(package) is called at the end of import_row
    end
    if(amount = row.at(9))
      import_price package, :public, amount.tr(',', '.').to_f
      if(efp = package._price_exfactory)
        import_price(package, :exfactory, efp.to_f)
      end
    end
    package
  end
  def import_price(package, type, amount)
    dotype = :"price_#{type}"
    # if this price has been edited manually we won't overwrite
    unless((data_origin = package.data_origin(dotype)) \
       && data_origin.to_s.include?('@'))
      if(price = package.price(type, 'DE'))
        if(price != amount)
          price.amount = amount
        end
      else
        price = Util::Money.new(amount, type, 'DE')
        package.add_price(price)
      end
      package.data_origins.store dotype, :gkv
    end
  end
  def import_product(package, row)
    name = product_name(row)
    search = name.dup
    product = nil
    candidates = []
    until(product || search.empty? || candidates.size > 1)
      candidates = Drugs::Product.search_by_name(search)
      if(candidates.size == 1)
        product = candidates.first
        product.name.add_synonym(name) && save(product)
      end
      search.sub!(/(\s|^)\S*$/, '')
    end
    if(product.nil?)
      @created_products += 1
      product = Drugs::Product.new
      product.name.de = name
      save product
    end
    product
  end
  def import_sequence(product, package, row)
    substances = []
    doses = []
    [3, 10, 13].each { |idx|
      if(name = row.at(idx))
        substances.push(import_substance(name))
        doses.push(Drugs::Dose.new(row.at(idx + 1),
                                   row.at(idx + 2)))
      end
    }
    galform = import_galenic_form(row)
    sequence = product.sequences.find { |seq|
      doses = seq.doses
      seq.galenic_forms == [galform] \
        && seq.substances == substances \
        && (doses.empty? || doses.inject { |a, b| a + b } == dose)
    }
    if(sequence.nil?)
      @created_sequences += 1
      sequence = Drugs::Sequence.new
      composition = Drugs::Composition.new
      substances.each_with_index { |sub, idx|
        act = Drugs::ActiveAgent.new(sub, doses.at(idx))
        act.composition = composition
      }
      composition.galenic_form = galform
      composition.sequence = sequence
      save composition
      sequence.product = product
      save sequence
    end
    sequence
  end
  def import_substance(substance_name)
    if(substance_name)
      substance = Drugs::Substance.find_by_name(substance_name)
      if(substance)
        @existing_substances += 1
      else
        @created_substances += 1
        substance = Drugs::Substance.new
        substance.name.de = substance_name
        save substance
      end
      substance
    end
  end
  def postprocess
    Drugs::Package.search_by_code(:type => 'zuzahlungsbefreit',
                                  :value => 'true',
                                  :country => 'DE').each { |package|
      pzn = package.code(:cid).value
      unless(@confirmed_pzns.include?(pzn))
        @deleted += 1
        package.code(:zuzahlungsbefreit).value = false
        save package
      end
    } unless(@confirmed_pzns.empty?)
    Drugs::Product.all { |product|
      unless(product.company)
        unless(product.name.de)
          @missingname_uids.push product.odba_id
        else
          keys = product.name.de.split
          key = keys.pop
          if(key == 'Comp')
            key = keys.pop
          end
          company = Business::Company.find_by_name(key)
          if(company.nil?)
            companies = Business::Company.search_by_name(key)
            if(companies.size == 1)
              company = companies.pop
            end
          end
          if(company)
            @assigned_companies += 1
            product.company = company
            save product
          end
        end
      end
    }
    Drugs::Composition.all { |composition|
      next if(composition.active_agents.size < 2)
      composition.active_agents.dup.each { |agent|
        next unless composition.active_agents.include?(agent)
        name = agent.substance.name.de
        if(other = composition.active_agents.find { |candidate|
          candidate != agent \
            && candidate.substance.name.de[0,name.length] == name })
          qty = other.dose.qty
          if(qty > 0 && qty == qty.to_i && !other.chemical_equivalence)
            agent, other = other, agent
          end
          if(agent.chemical_equivalence)
            raise "multiple chemical equivalences in #{composition.parts.first.package.code(:cid)}"
          end
          @assigned_equivalences += 1
          composition.remove_active_agent(other)
          agent.chemical_equivalence = other
          save agent
          save other
          save composition
        end
      }
    }
  end
  def product_name(row)
    if data = row.at(0)
      capitalize_all(data.gsub(/[^A-Z\s]/, '').gsub(/\s+/, ' ')).strip
    end
  end
  def report
    doubtfuls = @doubtful_pzns.collect do |pzn|
      "http://de.oddb.org/de/drugs/package/pzn/#{pzn}"
    end
    missingnames = @missingname_uids.collect do |uid|
      "http://de.oddb.org/de/drugs/product/uid/#{uid}"
    end
    [
      sprintf("Imported %5i Zubef-Entries on %s:",
              @count, Date.today.strftime("%d.%m.%Y")),
      sprintf("Visited  %5i existing Zubef-Entries", @existing),
      sprintf("Visited  %5i existing Companies",
              @existing_companies),
      sprintf("Visited  %5i existing Substances",
              @existing_substances),
      sprintf("Created  %5i new Zubef-Entries", @created),
      sprintf("Created  %5i new Products", @created_products),
      sprintf("Created  %5i new Sequences", @created_sequences),
      sprintf("Created  %5i new Companies", @created_companies),
      sprintf("Created  %5i new Substances", @created_substances),
      sprintf("Assigned %5i Chemical Equivalences",
              @assigned_equivalences),
      sprintf("Assigned %5i Companies", @assigned_companies),
      sprintf("Created  %5i Incomplete Packages:", doubtfuls.size),
    ].concat(doubtfuls) +
    [
      sprintf("Created  %5i Product(s) without a name (missing product name):", missingnames.size),
    ].concat(missingnames)
  end
  def sanitize_substance_name(str)
    str.to_s.downcase.gsub(/[^a-z]/, '')
  end
  def save(obj)
    obj.save
  end
  def process_page rows
    rows.each do |row|
      import_row row
    end
  end
end
  end
end
