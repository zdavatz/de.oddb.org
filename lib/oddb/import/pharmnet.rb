#!/usr/bin/env ruby
# Import::PharmNet -- de.oddb.org -- 15.10.2007 -- hwyss@ywesee.com

require 'fileutils'
require 'htmlentities'
require 'mechanize'
require 'oddb/import/import'
require 'oddb/import/rtf'
require 'oddb/util/mail'
require 'pp'

module ODDB
  module Import
    module PharmNet
class EncodedParser < WWW::Mechanize::Page
  @@iconv = Iconv.new('utf8', 'latin1')
  def initialize(uri=nil, response=nil, body=nil, code=nil)
    body = @@iconv.iconv(body.gsub(/iso-8859-1/i, 'utf-8'))
    ## HtmlEntities seems to kill the parser, do it manually for now
    #htmlentities = HTMLEntities.new
    #body = htmlentities.decode(body)
    body.gsub! '&aacute;', 'á'
    body.gsub! '&agrave;', 'à'
    body.gsub! '&auml;', 'ä'
    body.gsub! '&eacute;', 'é'
    body.gsub! '&egrave;', 'è'
    body.gsub! '&euml;', 'ë'
    body.gsub! '&iacute;', 'í'
    body.gsub! '&igrave;', 'ì'
    body.gsub! '&iuml;', 'ï'
    body.gsub! '&oacute;', 'ó'
    body.gsub! '&ograve;', 'ò'
    body.gsub! '&ouml;', 'ö'
    body.gsub! '&uacute;', 'ú'
    body.gsub! '&ugrave;', 'ù'
    body.gsub! '&uuml;', 'ü'
    super(uri, response, body, code)
  end
end
class RenewableAgent < SimpleDelegator
  def initialize agent
    agent.pluggable_parser.html = EncodedParser
    super
  end
  def renew!
    agent = __getobj__.class.new
    agent.pluggable_parser.html = EncodedParser
    __setobj__ agent
  end
end
class TermedRtf < Rtf
  def initialize(term)
    @term = term
  end
end
class FiParser < TermedRtf
  def identify_chapter buffer
    name = case buffer 
           when /^1[08]\.?\s*Stand/i 
             'date'
           when /^14\.?\s*Sonstige\s+Hinweise/i 
             'other_advice'
           when /^(2|11)\.?\s*(Verschreibung|Verkauf)/i 
             'sale_limitation'
           when /^1\.?\s*Bezeichnung/i 
             'name'
           when /^[23]\.?\s*(Qualitative|Zusammensetzung)/i  
             'composition'
           when /^3\.?\s*Darreichung/i  
             'galenic_form'
           when /^3\.1\.?\s*Stoff/i  
             'substance_group'
           when /^3\.2\.?\s*(Arzneilich|Bestandteile)/i  
             'active_agents'
           when /^4(\.1)?\.?\s*Anwendung/i 
             'indications'
           when /^(10|4\.2)\.?\s*Dosierung/i 
             'dosage'
           when /^11\.?\s*Art\s+und\s+Dauer/i 
             'application'
           when /^(5|4\.3)\.?\s*Gegenanzeigen/i 
             'counterindications'
           when /^(8|4\.4)\.?\s*(Besondere\s+)?Warnhinweise/i 
             'precautions'
           when /^(7|4\.5)\.?\s*Wechselwirkungen/i 
             'interactions'
           when /^4\.6\.?\s*(Anwendung|Schwangerschaft)/i 
             'pregnancy'
           when /^4\.7\.?\s*Auswirkung/i 
             'driving_ability'
           when /^(6|4\.8)\.?\s*Nebenwirkungen/i 
             'unwanted_effects'
           when /^(12|4\.9)\.?\s*(Notfall|Überdosierung)/i 
             'overdose'
           when /^4\.?\s*Klinisch/i 
             'clinical'
           when /^5\.1\.?\s*Pharmakodynamisch/i 
             'pharmacodynamics'
           when /^13\.2\.?\s*Toxikologisch/i 
             'toxicology'
           when /^(13\.3|5\.2)\.?\s*Pharmakokineti(sch|k)/i 
             'pharmacokinetics'
           when /^13\.4\.?\s*Bioverfügbarkeit/i 
             'bioavailability'
           when /^5\.3\.?\s*Präklinisch/i 
             'preclinicals'
           when /^(13|5)\.?\s*Pharmakologisch/i 
             'pharmacology'
           when /^(3\.3|6\.1)\.?\s*(Liste|Hilfsstoffe?|Sonstige\s+Bestandteile)/i 
             'excipients'
           when /^(9|6\.2)\.?\s*(Wichtigste\s+)?Inkompatibilitäten/i 
             'incompatibilities'
           when /^(15|6\.3)\.?\s*(Dauer|Haltbarkeit)/i 
             'shelf_life'
           when /^(16|6\.4)\.?\s*(Besondere|Lagerung|Aufbewahrung)/i 
             'storage'
           when /^6\.5\.?\s*(Art|Behältnis)/i, 
                /^17\.?\s*Darreichungsformen\s+und\sPackung/
             'packaging'
           when /^6\.6\.?\s*(Besondere|Hinweis|Entsorgung)/i 
             'disposal'
           when /^6\.?\sPharmazeutisch/i 
             'pharmaceutic'
           when /^(19|7)\.?\s*(Name|Pharmazeutischer|Inhaber)/i  
             'company'
           when /^20\.?\s*(Name|Hersteller)/i  
             'producer'
           when /^8\.?\s*Zulassung/i 
             'registration'
           when /^9\.?\s*Datum/i 
             'registration_date'
           when /^zusätzliche Angaben/i
             'additional_information'
           end
    if(name && !@document.chapter(name))
      @document.add_chapter Text::Chapter.new(name)
    end
    super
  end
  def _sanitize_text(value)
    if @buffer.empty? && @buffer.is_a?(Text::Paragraph)
      value.gsub! /^([BF][A-Z0-9]{1,2})?\s*/, ''
    end
  end
end
class PiParser < TermedRtf
  def identify_chapter buffer
    name = nil
    if(/\b#@term\b/i.match buffer)
      name = case buffer 
             when /wof(ü|Ü|ue)r\s+(wird|werden)\s+(es|sie)\s+(angewendet|eingenommen)/i,
                  /wird\s+angewendet$/i
               'indications'
             when /Wie\s+(ist|sind).+?(anzuwenden|einzunehmen)\?/i
               'application'
             when /vor\s+der\s+(Anwendung|Einnahme)\s+von/i 
               'precautions'
             when /^([56]\.?\s*)?Wie\s+(ist|sind).+?aufzubewahren/i
               'storage'
             when /^Bitte\s.+für\s+Kinder\s+nicht\s+erreichbar/i
               'personal'
             when /^([45]\.?\s*)?Welche\s+Nebenwirkungen/i, /^Nebenwirkungen:?$/i
               'unwanted_effects'
             when /Behandlungserfolg/i
               nil ## prevent composition if this is a dodgy match
             else
               'composition'
             end
    else
      name = case buffer
             when /^([45]\.?\s*)?Welche\s+Nebenwirkungen/i, /^Nebenwirkungen:?$/i
               'unwanted_effects'
             when /^(4\.?\s*)?Verhalten\s+im\s+Notfall/i
               'emergency'
             when /^(6\.?\s*)?(Weitere\s+)?(Informationen|Angaben)/i,
                  /^(6\.?\s*)?Gebrauchsanleitung/i,
                  /^Zusätzliche\s+Informationen/i
               'additional_information'
             when /^Anwendungsgebiete/i
               'indications'
             when /^Vorsichtsma(ss|ß)nahmen/i 
               'precautions'
             when /^Dosierung\s*($|und)/i, /^Dosierungsanleitung/
               'application'
             when /Angaben\s+zur\s+Haltbarkeit/i 
               'storage'
             when /^Gegenanzeigen/i
               'counterindications'
             when /^Darreichungsform/i
               'packaging'
             when /^(Hersteller.+)?Pharmazeutischer\s+Unternehmer/i,
                  /^Pharmazeutischer\s+Hersteller/i
               'company'
             when /^Stand\b/, /wurde\s+zuletzt\s+überarbeitet/i
               'date'
             when /^(Sehr\s+geehrte|Liebe)r?\s+Patient/i, 
                  /^Bitte\s.+für\s+Kinder\s+nicht\s+erreichbar/i
               'personal'
             end
    end
    composition = @document.chapter('composition')
    if(name && (name == 'composition' || composition))
      chapter = @document.chapter(name)
      if(chapter.nil?)
        @document.add_chapter Text::Chapter.new(name)
      elsif(chapter.paragraphs.size == 1 \
            && /^\d+/.match(chapter.paragraphs.first)) 
        ## some PI insert a document-overview after the composition, in which
        #  case we have an erroneous chapter, identified by only consisting of
        #  a heading. In that case:
        composition.append chapter
        @document.remove_chapter chapter
        @document.add_chapter Text::Chapter.new(name)
      end
    end
    super
  end
  def _sanitize_text(value)
    ## some rtfs have unusable information prior to the actual PI
    case value
    when /^PCX\b/
      init
    when /Gebrauchsinformation/
      init if /Recyclinglogo/.match(current_chapter.to_s)
    end
    if @buffer.empty? && @buffer.is_a?(Text::Paragraph)
      value.gsub! /^([P][A-Z0-9]{1,2})?\s*/, ''
    end
  end
end
class Import < Import
  attr_reader :errors
  def initialize
    @stop = /(Pharma(ceuticals|zeutische\s*Fabrik)?|Arzneim(ittel|\.)|GmbH|[u&]\.?\s*Co\.?|Kg|Ltd\.?|')\s*/i
    @htmlentities = HTMLEntities.new
    @result_cache = {}
    @distance_cache = {}
    @errors = []
    @assigned = Hash.new 0
    @removed = Hash.new 0
    @not_removed = Hash.new 0
    @repaired = 0
    @reparsed_fis = 0
    @products_created = 0
    @sequences_created = 0
    @packages_created = 0
    @archive = File.join ODDB.config.var, 'rtf', 'pharmnet'
    @sources = {}
    FileUtils.mkdir_p @archive
    @latest = File.join ODDB.config.var, 'html', 'pharmnet', 'latest.html'
    FileUtils.mkdir_p File.dirname(@latest)
    super
  end
  def assign_info(key, agent, data, sequence, opts)
    return(remove_info key, sequence, opts) unless(url = data[key])

    term = data[:search_term]
    doc = import_rtf key, agent, url, term, opts
    doc.date = data[:"date_#{key}"]
    # arbitrary cutoff: fachinfos with less than 5 chapters can't be right...
    if doc.chapters.size > 5
      _assign_info key, doc, sequence, opts
    else
      ODDB.logger.debug('PharmNet') { 
        sprintf("Discarding %s for %s (%s)", key, sequence_name(sequence), term)
      }
      remove_info key, sequence, opts
    end
  rescue Timeout::Error, StandardError => error
    ODDB.logger.error('PharmNet') {
      sprintf("%s: %s", error.class, error.message) << "\n" << error.backtrace.join("\n")
    }
    @errors.push [ sequence ? sequence_name(sequence) : '', error.message,
      error.backtrace.find { |ln| /pharmnet/.match ln }.to_s.strip, url ]
  end
  def _assign_info(key, doc, sequence, opts={})
    info = sequence.send(key)
    return unless info.empty? || opts[:replace]

    ODDB.logger.debug('PharmNet') { 
      sprintf("Assigning %s to %s", key, sequence_name(sequence))
    }
    info.de = doc
    @assigned[key] += 1
    doc.save
    info.save
    sequence.save
  end
  def assign_registration(sequence, registration)
    if(registration && sequence.code(:registration, 'EU') != registration)
      ODDB.logger.debug('PharmNet') { 
        sprintf('Assigning Registration-Number %s to %s', 
                registration, sequence_name(sequence))
      }
      if unique_registration? registration
        conflict = Drugs::Sequence.find_by_code(:value   => registration,
                                                :type    => 'registration',
                                                :country => 'EU')
        if(conflict && conflict != sequence)
          raise sprintf("Multiple assignment of Registration-Number %s (%s-%i/%s-%i)",
                        registration, sequence_name(sequence), sequence.odba_id,
                        conflict.name.de, conflict.odba_id)
        end
      end
      if(code = sequence.code(:registration, 'EU'))
        code.value = registration
      else
        sequence.add_code Util::Code.new(:registration, registration, 'EU')
      end
      sequence.save
    end
  end
  def best_data(sequence, result)
    sname = sequence.name
    unless sname.de
      sname = sequence.product.name
    end
    comparison = [
      sname,
      (gf = sequence.galenic_forms.first) && gf.description,
      (comp = sequence.company) && comp.name,
    ].collect { |ml| ml ? ml.de : '' }
    suitable = suitable_data comparison, result, 
                             :subcount => sequence.active_agents.size
    max = 0
    relevances = suitable.collect { |data|
      rel = composition_relevance(sequence.active_agents, data)
      max = rel if rel > max
    }
    contenders = []
    relevances.each_with_index { |rel, idx|
      if(rel == max)
        contenders.push suitable.at(idx)
      end
    }
    contenders.sort_by { |data| data[:date_fachinfo] || data[:date_patinfo] }.last
  end
  def _composition_paired_relevance(agent, detail)
    adose = agent.dose.to_f
    ddose = detail[:dose].to_f
    drel = if(adose == 0 || adose == ddose)
             1
           else
             if(adose < ddose)
               ddose, adose = adose, ddose
             end
             ddose / adose
           end rescue 0
    ignore = /hydrochlorid/
    subname = agent.substance.name.de.gsub(ignore, '')
    detname = detail[:substance].gsub(ignore, '')
    srel = ngram_similarity(subname, detname)
    drel + srel
  end
  def composition_relevance(agents, data)
    details = data[:composition]
    participants = [agents.size, details.size].max
    relevances = {}
    agents.each_with_index { |agent, aidx|
      details.each_with_index { |detail, didx|
        relevances.store [aidx, didx], 
          _composition_paired_relevance(agent, detail)
      }
    }
    max = 0
    exclusive_permutation(participants).each { |pairs|
      sum = pairs.inject(0) { |memo, pair|
        memo + relevances[pair].to_f
      }
      if sum > max
        data.store :pairs, pairs
        max = sum 
      end
    }
    data.store :relevance, max / participants
  end
  def create_sequence(term, data, company, product, galform)
    pname, gfname, cname = data[:data]
    official = pname[/^[^\d(]+/].strip
    company_name = company.name.de.gsub(@stop, '').strip
    official_with_company = [ official, company_name ].join(' ')
    term_with_company = [ term, company_name ].join(' ')
    unless product
      @products_created += 1
      product = Drugs::Product.new
      product.name.de = term_with_company
      product.company = company
      product.save
    end
    @sequences_created += 1
    sequence = Drugs::Sequence.new
    composition = Drugs::Composition.new
    composition.sequence = sequence
    composition.galenic_form = galform
    data[:composition].each do |act|
      substance = import_substance act[:substance]
      agent = Drugs::ActiveAgent.new substance, act[:dose]
      agent.composition = composition
      agent.save
    end
    composition.save
    sequence.name.de = official_with_company
    sequence.product = product
    sequence.save
    sequence
  end
  def exclusive_permutation(participants)
    left = (0...participants).to_a
    right = left.dup
    _exclusive_permutation(left, right)
  end
  def _exclusive_permutation(left, right)
    if(left.size == 1)
      [[[left.first, right.first]]]
    else
      result = []
      left.each { |first|
        pass_left = left.reject { |val| val == first }
        right.inject(result) { |memo, second|
          pass_right = right.reject { |val| val == second }
          _exclusive_permutation(pass_left, pass_right).each { |rest|
            memo.push [[first, second]].concat(rest)
          }
        }
      }
      result
    end
  end
  def extract_details(page)
    data = {}
    _extract_newest_link(data, :fachinfo, "Fachinformation", page)
    _extract_newest_link(data, :patinfo, "Gebrauchsinformation", page)
    table = (page/"table[@border=1]").first or return data
    rows = (table/"tr")[1..-1] || []
    composition = rows.collect { |row|
      spans = row/"span"
      {
        :ask_nr    => _extract_details(spans[0]),
        :substance => _extract_details(spans[1]),
        :dose      => parse_dose(_extract_details(spans[2])),
      }
    }
    data.store :composition, composition
    previous = ''
    (page/"span[@class='wbtxt']").each { |span|
      if /Reg\.?-Nr\.?/.match previous
        data.store :registration, span.inner_text
        break
      end
      previous = span.inner_text
    }
    data
  end
  def _extract_details(span)
    @htmlentities.decode(span.inner_html).gsub(/[\t\n]|\302\240/, '')
  end
  def _extract_newest_link(data, key, search, page)
    hrefs = page.links.inject([]) { |memo, link|
      if(/#{search}\b/i.match link.text)
        str = link.text[/(\d{2}\.){2}\d{4}/]
        memo.push [Date.new(*str.split('.').reverse.collect { |num| num.to_i}), 
          link.href]
      end
      memo
    }.sort
    if(oldest = hrefs.last) 
      data.update :"date_#{key}" => oldest.first, key => oldest.last
    end
  end
  def extract_result(agent, page)
    form = page.form("titlesForm")
    node = form.form_node
    result = _extract_result node
    hrefs = (node/"a").select { |link| 
      /^\d*1(-\d+)?$/.match link.inner_text 
    }.collect { |link| 
      link["href"] 
    }.sort.uniq[1..-1]
    if(hrefs)
      hrefs.each_with_index { |href, idx|
        page = agent.get href
        result.concat _extract_result(page.form("titlesForm").form_node)
      }
    end
    result
  end
  def _extract_result node
    rows = (node/"tr")[2..-4] || []
    rows.collect { |row|
      { 
        :data => (row/"td//span[@title]").collect { |span| span["title"] },
        :href => (row/"a[@name]").first["href"], 
      }
    }
  end
  def fix_composition(agents, data)
    details = data[:composition]
    data[:pairs].each { |aidx, didx|
      agent = agents[aidx]
      detail = details[didx]
      if(agent.dose.nil? || agent.dose.qty == 0)
        if(agent.substance == detail[:substance])
          agent.dose = detail[:dose]
          agent.save
          @repaired += 1
        elsif(!agent.chemical_equivalence)
          agent.chemical_equivalence = Drugs::ActiveAgent.new agent.substance, agent.dose
          agent.chemical_equivalence.save
          substance = import_substance detail[:substance]
          agent.substance = substance
          agent.dose = detail[:dose]
          agent.save
          @repaired += 1
        end
      end
    }
  end
  def get_details(agent, page, result)
    form = page.form("titlesForm")
    form.field("parinfo").value = 'true'
    form.field("docBaseName").value = form.field('baseName').value
    form.field("magicrequestid").value = rand.to_s
    uri = URI.parse result[:href]
    form.action = uri.path
    uri.query.split('&').each { |param|
      key, value = param.split('=', 2)
      if field = form.field(key)
        field.value = value
      end
    }
    page = form.submit
  end
  def get_search_form(agent)
    index = "http://www.pharmnet-bund.de/dynamic/de/am-info-system/index.html"
    page = agent.get index
    form = page.form("pharmnet_amis_off_ppv")
    page = form.submit
    link = page.links.find { |l| /(?<!nicht )akzeptieren/i.match l.text }
    page = link.click
    link = page.links.find { |l| /filter einblenden/i.match l.text }
    form = page.form("search_form")
    form.field("setExpressions").value = "addLimits"
    form.action = link.href
    page = form.submit
    form = page.form("search_form")
    link = page.links.find { |l| l.attributes["id"] == 'goME' }
    form.action = link.href
    form
  end
  def get_search_result(agent, term, sequence=nil, opts={})
    opts = { :info_unrestricted => false,
             :repair => false, :retries => 3}.merge opts
    good = nil
    term = term.dup
    ODDB.logger.debug('PharmNet') { sprintf('Searching for %s', term) }
    result = []
    while result.empty?
      return if term.length < 3
      good = term.dup
      result.concat search(agent, term, sequence, opts)
      if(result.empty?)
        good = term.gsub(/\s+/, '-')
        result.concat search(agent, good, sequence, opts)
      end
      term.gsub! /\s*[^\s]+$/, ''
    end
    result.each { |data| data.store(:search_term, good) }
    result
  rescue Timeout::Error, StandardError => error
    ODDB.logger.error('PharmNet') {
      sprintf("%s: %s", error.class, error.message) << "\n" << error.backtrace.join("\n")
    }
    retries ||= opts[:retries]
    if((error.is_a?(Timeout::Error) || /ServerError/.match(error.message)) \
       && retries > 0)
      seconds = opts[:retry_unit] * 4 ** (opts[:retries] - retries)
      ODDB.logger.debug('PharmNet') {
        sprintf("Waiting %i seconds for the server to recover...", seconds)
      }
      sleep seconds
      retries -= 1
      ODDB.logger.debug('PharmNet') {
        "Renewing Mechanize-agent and starting a new Session" }
      agent.renew!
      @search_form = nil
      retry
    else
      @errors.push [ sequence ? sequence_name(sequence) : '', error.message,
        error.backtrace.find { |ln| /pharmnet/.match ln }.to_s.strip ]
    end
    nil
  end
  def identify_details(agent, term, sequence=nil, 
                       opts = { :info_unrestricted => false, 
                                :repair => false, :retries => 3})
    if result = get_search_result(agent, term, sequence, opts)
      if result.size == 1
        result.first
      else
        best_data sequence, result
      end
    end
  end
  def identify_product(term, data, company)
    pname, gfname, cname = data[:data]
    official = pname[/^[^\d(]+/].strip
    company_name = company.name.de.gsub(@stop, '').strip
    official_with_company = [ official, company_name ].join(' ')
    term_with_company = [ term, company_name ].join(' ')
    [official_with_company, official, term_with_company, term].each do |cnd|
      if (candidate = Drugs::Product.find_by_name(cnd)) \
        && candidate.company == company
        return candidate
      else
        Drugs::Product.search_by_name(cnd).each do |candidate|
          if candidate.company == company
            return candidate
          end
        end
      end
    end
    nil
  end
  def identify_sequence(data, product, galform)
    if product
      doses = data[:composition].collect do |act| act[:dose] end.compact.sort
      product.sequences.find do |seq|
        seq.compositions.size == 1 \
          && seq.doses.compact.sort == doses \
          && seq.galenic_forms == [galform]
      end
    end
  end
  def import(agent, sequences, opts = { :replace => false, 
                                        :reload  => false, 
                                        :remove  => false, 
                                        :repair  => false,
                                        :reparse => false,
                                        :retries => 3,
                                        :retry_unit => 60 })
    Util::Mail.notify_admins sprintf("%s: %s", Time.now.strftime('%c'),
                                     self.class), _import(agent, sequences, opts)
  end
  def _import(agent, sequences, opts = { :replace => false, 
                                         :reload  => false, 
                                         :remove  => false, 
                                         :repair  => false,
                                         :reparse => false,
                                         :retries => 3,
                                         :retry_unit => 60 })
    agent = RenewableAgent.new agent
    if resume = opts[:resume]
      resume = resume.to_s.downcase
      sequences = sequences.select { |sequence| 
        (name = sequence_name(sequence)) && name.downcase >= resume
      }
    else
      sequences = sequences.select { |sequence|
        sequence_name(sequence)
      }
    end
    sequences = sequences.sort_by { |sequence|
      sequence_name(sequence)
    }
    count = 0
    head = sequences.first.name
    @checked = "Checked 0 Sequences"
    ## let odba cache release unneeded sequences ...
    sequences.collect! { |sequence| sequence.odba_id }
    while odba_id = sequences.shift
      begin
        ## ... and refetch them when necessary
        sequence = ODBA.cache.fetch(odba_id)
        count += 1
        @checked = sprintf "Checked %i Sequences from '%s' to '%s'",
                          count, head, sequence_name(sequence)
        process(agent, sequence, opts)
      rescue ODBA::OdbaError
      end
    end
    report
  end
  def import_company(name)
    term = clean = name.gsub(@stop, '').strip
    company = Business::Company.find_by_name(term)
    while company.nil? && !term.empty?
      company = Business::Company.search_by_name(term).find do |gf|
        relevance = ngram_similarity clean, gf.name.de.gsub(@stop, '')
        relevance > 0.8
      end
      term = term.gsub /(^|\s)+\S+\s*$/, ''
    end
    if company
      company.name.add_synonym name
    else
      company = Business::Company.new
      company.name.de = name
    end
    company.save
    company
  end
  def import_galenic_form(description)
    galform = Drugs::GalenicForm.find_by_description(description)
    unless galform
      galform = Drugs::GalenicForm.search_by_description(description).find do |gf|
        sim = ngram_similarity description, gf.description.de
        sim > 0.75
      end
      if galform
        galform.description.add_synonym description
        galform.save
      end
    end
    unless galform
      galform = Drugs::GalenicForm.new
      galform.description.de = description
      galform.save
    end
    galform
  end
  def import_missing(agent, term, opts={})
    @checked = "Searched for FIs/GIs for '#{term}'"
    opts = { :skip_totals => true }.merge opts
    agent = RenewableAgent.new agent
    if result = get_search_result(agent, term, nil, opts)
      result.each do |data|
        company, product, galform = nil
        sequence = nil
        registration = data[:registration]
        if registration && unique_registration?(registration)
          sequence = Drugs::Sequence.find_by_code :value => registration
        end
        unless sequence
          pname, gfname, cname = data[:data]
          galform = import_galenic_form gfname
          company = import_company cname
          product = identify_product term, data, company
          sequence = identify_sequence data, product, galform
        end
        if sequence
          if opts[:repair]
            pname, gfname, cname = data[:data]
            if product = sequence.product
              product.company ||= import_company cname
            end
            company_name = product.company.name.de.gsub(@stop, '').strip
            official = pname[/^[^\d(]+/].strip
            sequence.name.de = [ official, company_name ].join(' ')
            agents = sequence.active_agents
            relevance = composition_relevance agents, data
            fix_composition agents, data
          end
        else
          sequence = create_sequence term, data, company, product, galform
        end
        assign_registration sequence, data[:registration]
        assign_info(:fachinfo, agent, data, sequence, opts)
        assign_info(:patinfo, agent, data, sequence, opts)
        import_package sequence, data, opts
      end
    end
    report opts
  end
  def import_package(sequence, data, opts={})
    pname, gfname, _ = data[:data]
    if match = /^(.*?)\s*-\s*OP(\d+)$/i.match(pname)
      size = match[2].to_i
      package = sequence.packages.find do |pac|
        pac.size == size
      end
      if package.nil?
        @packages_created += 1
        package = Drugs::Package.new
        package.add_code Util::Code.new(:cid, "oddb#{package.uid}", 'DE')
        package.name.de = match[1]
        part = Drugs::Part.new
        part.size = size
        part.unit = import_unit gfname
        part.package = package
        part.composition = sequence.compositions.first
        part.save
        package.sequence = sequence
        package.save
      end
      package
    end
  end
  def import_rtf(key, agent, url, term, opts = { :reparse => false, 
                                                 :reload  => false})
    pklass = case key
             when :fachinfo
               FiParser
             when :patinfo
               PiParser
             end
    path = File.join @archive, File.basename(url)
    doc = Text::Document.find_by_source(url)
    ODDB.logger.debug('PharmNet') { 
      sprintf('Comparing %s-sources for %s', key, term) }
    if(doc.nil? || (opts[:reparse] && !@sources[url]))
      @sources.store url, true 
      io = nil
      if(opts[:reload] || !File.exist?(path))
        ODDB.logger.debug('PharmNet') {
          sprintf('Downloading %s for %s from %s', key, term, url) }
        file = agent.get url
        file.save path
        ODDB.logger.debug('PharmNet') {
          sprintf('Saving %s for %s in %s', key, term, path) }
        io = StringIO.new(file.body)
      else 
        ODDB.logger.debug('PharmNet') {
          sprintf('Reading %s for %s from %s', key, term, path) }
        file = agent.get url
        io = File.open(path)
      end
      term = term.downcase.gsub(/[\s-]/, '.')
      chapters = []
      new = nil
      while !term.empty? && chapters.size < 4
        ODDB.logger.debug('PharmNet') {
          sprintf('Parsing %s with term: %s', key, term) }
        io.rewind
        new = pklass.new(term).import io
        chapters = new.chapters
        term = term.gsub /(\A|\.)[^.]*$/, ''
      end
      ## ensure that chapter-headings are bold
      new.chapters.each { |chapter|
        if((paragraph = chapter.paragraphs.first) \
           && (format = paragraph.formats.first))
          format.augment "b"
        end
      }
      new.source = url
      if doc
        doc.chapters.replace chapters
        doc.save
      else
        doc = new
      end
    end
    doc
  end
  def import_substance(name)
    substance = Drugs::Substance.find_by_name name
    unless(substance)
      substance = Drugs::Substance.new
      substance.name.de = name
      substance.save
    end
    substance
  end
  def import_unit(name)
    unit = Drugs::Unit.find_by_name name
    unless unit
      unit = Drugs::Unit.search_by_name(name).find do |unt|
        sim = ngram_similarity name, unt.name.de
        sim > 0.75
      end
      if unit
        unit.name.add_synonym name
        unit.save
      end
    end
    unless unit
      unit = Drugs::Unit.new
      unit.name.de = name
      unit.save
    end
    unit
  end
  def ngram_similarity(str1, str2, n=5)
    str1 = u(str1).downcase.gsub(/[\s,.\-\/]+/, '')
    str2 = u(str2).downcase.gsub(/[\s,.\-\/]+/, '')
    if(str1.length < str2.length)
      str1, str2 = str2, str1
    end
    parts = [ str1.length - n, 0 ].max + 1
    count = 0
    parts.times { |idx|
      if(str2.include? str1[idx, n])
        count += 1
      end
    }
    count.to_f / parts
  end
  def parse_dose(str)
    Drugs::Dose.new(str[/^\d*\.\d*/].to_f, str[/[^\d\.]+$/])
  end
  def process(agent, sequence, opts = { :replace => false,
                                        :reload  => false,
                                        :remove  => false, 
                                        :repair  => false,
                                        :reparse => false,
                                        :retries => 3,
                                        :retry_unit => 60 })

    return(reparse_fachinfo agent, sequence) if opts[:reparse]
    return unless sequence.fachinfo.empty? || sequence.patinfo.empty? \
                    || opts[:replace] || opts[:remove]
    data = identify_details(agent, sequence_name(sequence), sequence, opts)

    return(remove_infos sequence, opts) unless data

    cutoff = composition_relevance(sequence.active_agents, data)
    return(remove_infos sequence, opts) if(cutoff <= 1.25) # arbitrary value

    assign_info(:fachinfo, agent, data, sequence, opts)
    assign_info(:patinfo, agent, data, sequence, opts)

    fix_composition sequence.active_agents, data if(opts[:repair])

    # assign registration number if really good match
    return if(cutoff < 2) # arbitrary value
    assign_registration sequence, data[:registration]
  rescue Timeout::Error, StandardError => error
    ODDB.logger.error('PharmNet') {
      sprintf("%s: %s", error.class, error.message) << "\n" << error.backtrace.join("\n")
    }
    @errors.push [ sequence_name(sequence), error.message,
      error.backtrace.find { |ln| /pharmnet/.match ln }.to_s.strip ]
  end
  def remove_info(key, sequence, opts)
    info = sequence.send(key)
    if opts[:remove] && info.de
      @removed[key] += 1
      ODDB.logger.debug('PharmNet') { 
        sprintf('Removing Fachinfo from %s', sequence_name(sequence))
      }
      info.de = nil
      sequence.save
    elsif info.de
      @not_removed[key] += 1
    end
  end
  def remove_infos(sequence, opts)
    remove_info :fachinfo, sequence, opts
    remove_info :patinfo, sequence, opts
  end
  def reparse_fachinfo(agent, sequence)
    if((info = sequence.fachinfo.de) && (source = info.source) \
       && (doc = import_rtf :fachinfo, agent, source, sequence_name(sequence),
                            :reparse => true))
      @reparsed_fis += 1
      info.chapters.replace doc.chapters
      info.save
    end
  end
  def report opts={}
    fi_sources = { }
    pi_sources = { }
    fi_count = pi_count = 0
    unless opts[:skip_totals]
      Drugs::Sequence.all { |sequence|
        if(doc = sequence.fachinfo.de)
          fi_count += 1
          fi_sources[doc.source] = true
        end
        if(doc = sequence.patinfo.de)
          pi_count += 1
          pi_sources[doc.source] = true
        end
      }
    end
    [ @checked,
      "",
      "Assigned #{@assigned[:fachinfo]} Fachinfos",
      "Removed #{@removed[:fachinfo]} Fachinfos",
      "Kept #{@not_removed[:fachinfo]} unconfirmed Fachinfos",
      ("Total: #{fi_sources.size} Fachinfos linked to #{fi_count} Sequences" \
        unless opts[:skip_totals]),
      "",
      "Assigned #{@assigned[:patinfo]} Patinfos",
      "Removed #{@removed[:patinfo]} Patinfos",
      "Kept #{@not_removed[:patinfo]} unconfirmed Patinfos",
      ("Total: #{pi_sources.size} Patinfos linked to #{pi_count} Sequences" \
        unless opts[:skip_totals]),
      "",
      "Created #@products_created Products",
      "Created #@sequences_created Sequences",
      "Created #@packages_created Packages",
      "",
      "Reparsed #@reparsed_fis Fachinfos",
      "Repaired #@repaired Active Agents",
      "",
      "Errors: #{@errors.size}",
    ].compact.concat(@errors.collect { |name, message, line, link|
      sprintf "%s: %s (%s) -> http://gripsdb.dimdi.de%s",
              name, message, line, link
    })
  end
  def result_page(form, term)
    form.field('term').value = term
    form.submit
  end
  def search(agent, term, sequence=nil, opts={})
    term = term.downcase
    @result_cache.fetch(term) do
      if(minimal = term[0,3])
        @result_cache.delete_if { |key, _|
          key < minimal
        }
      end
      @search_form ||= get_search_form agent
      ## if we need to repair the active agents, we want all results, otherwise only
      #  those that have a Fach- or PatInfo to parse.
      fi_only = opts[:info_unrestricted] \
        || (opts[:repair] && sequence && sequence.active_agents.any? { |act|
        act.dose.qty == 0 }) ? 'NO_RESTRICTION' : 'YES'
      set_fi_only(@search_form, fi_only)
      details = agent.transact {
        page = result_page @search_form, term
        if(found = _search_invalid? page, term)
          ODDB.logger.error('PharmNet') { 
            sprintf "Searched for '%s' but got result for '%s' - creating new session",
              term, found
          }
          agent.renew!
          @search_form = get_search_form agent
          set_fi_only(@search_form, fi_only)
          page = result_page @search_form, term
          if(_search_invalid? page, term)
            return []
          end
        end
        page.save @latest
        result = extract_result agent, page
        result.collect do |data|
          dpg = get_details agent, page, data
          detail = data.merge extract_details(dpg)
          detail.delete :href
          detail
        end
      }
      @result_cache.store term, details
    end
  end
  def _search_invalid?(page, term)
    div = (page/"div.wbsectionsubtitlebar").last
    if(div.nil?)
      ''
    elsif(!/Arzneimittelname:\s#{Regexp.escape(term)}\?/i.match(div.inner_text))
      div.inner_text[/Arzneimittelname:[^?]+/]
    end
  end
  def sequence_name sequence
    if sequence
      if name = sequence.name.de
        name
      elsif product = sequence.product
        product.name.de
      end
    end
  end
  def set_fi_only(form, status="YES")
    form.radiobuttons.find { |b| b.name == "WFTYP" && b.value == status }.check
  end
  def suitable_data(comparison, selection, opts = {})
    max = 0
    sums = []
    preselection = []
    ODDB.logger.debug('PharmNet') { 
      "Checking for suitable data in #{selection.size} results" 
    }
    selection.each_with_index { |data, idx|
      if(dists = _suitable_data(data, comparison, opts))
        sum = dists.inject { |a,b| a+b }
        max = sum if sum > max
        sums.push sum
        preselection.push data
      end
    }
    ODDB.logger.debug('PharmNet') { 
      "Found a preselection of #{preselection.size} results" 
    }
    result = []
    sums.each_with_index { |sum, idx|
      if sum == max
        result.push preselection[idx]
      end
    }
    ODDB.logger.debug('PharmNet') { 
      "Returning the best #{result.size} results" 
    }
    result
  end
  def _suitable_data(data, comparison, opts)
    opts[:cutoff] ||= 0.25
    idx = 0
    raw = data[:data].dup
    comp = comparison.dup
    
    unless(opts[:keep_dose])
      part = Regexp.escape(raw[1].to_s).gsub('\ ', ')|(')
      ptrn = /(#{part})|(\b\d+\s*m?g(\s*\/\s*\d+\s*h)?)[\-\s]*/i
      raw[0] = raw[0].gsub(ptrn, '')
      comp[0] = comp[0].gsub(ptrn, '')
    end

    tabl = /([a-z]{4,})tab.*/i
    raw[1] = raw[1].to_s.gsub(tabl, '\1')
    # Import::Csv::ProductInfos passes a comparison without Galenic Form if 
    #                           no suitable data is found on the first try
    if comp[1] 
      comp[1] = comp[1].to_s.gsub(tabl, '\1')
    end
    dists = raw.collect { |str|
      str = str.to_s
      othr = comparison[idx]
      other = othr ? othr.to_s : str
      idx += 1

      relevance = ngram_similarity str.gsub(@stop, ''), other.gsub(@stop, '')
      return if relevance < opts[:cutoff]
      relevance
    }
    if(subcount = opts[:subcount])
      cdist = (comp = data[:composition]) ? (subcount - comp.size).abs : subcount
      dists.push(cdist) unless cdist > 0
    else
      dists
    end
  end
  def unique_registration? code
    !/^EU/.match code.to_s
  end
end
    end
  end
end
