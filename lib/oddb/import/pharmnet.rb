#!/usr/bin/env ruby
# Import::PharmNet -- de.oddb.org -- 15.10.2007 -- hwyss@ywesee.com

require 'fileutils'
require 'htmlentities'
require 'oddb/import/import'
require 'oddb/import/rtf'
require 'oddb/util/mail'
require 'pp'

module ODDB
  module Import
    module PharmNet
class FiParser < Rtf
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
           when /^3\.2\.?\s*Arzneilich/i  
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
class FachInfo < Import
  def initialize
    @stop = /(Pharma(ceuticals|zeutische\s*Fabrik)?
             |Arzneim(ittel|\.)
             |GmbH
             |u\.?\s*Co\.?|Kg
             )\s*/ie
    @htmlentities = HTMLEntities.new
    @result_cache = {}
    @distance_cache = {}
    @errors = []
    @assigned = @removed = 0
    @archive = File.join ODDB.config.var, 'rtf', 'pharmnet'
    FileUtils.mkdir_p @archive
    @latest = File.join ODDB.config.var, 'html', 'pharmnet', 'latest.html'
    FileUtils.mkdir_p(File.dirname @latest)
    super
  end
  def assign_fachinfo(agent, sequence, 
                      opts = {:replace => false, :remove => false})
    return unless sequence.fachinfo.empty? || opts[:replace] || opts[:remove]
    url = nil
    term = sequence.name.de.dup
    ODDB.logger.debug('FachInfo') { sprintf('Searching for %s', term) }
    result = []
    while result.empty?
      return if term.length < 3
      result.concat search(agent, term)
      if(result.empty?)
        result.concat search(agent, term.gsub(/\s+/, '-'))
      end
      term.gsub! /\s*[^\s]+$/, ''
    end
    if result.size == 1
      data = result.first
    else
      data = best_data sequence, result
    end
    return(remove_fachinfo sequence, opts) unless data && (url = data[:fachinfo])

    cutoff = composition_relevance(sequence.active_agents, data[:composition])
    return(remove_fachinfo sequence, opts) if(cutoff <= 1.25) # arbitrary value

    doc = import_rtf agent, url
    # arbitrary cutoff: fachinfos with less than 5 chapters can't be right...
    if doc.chapters.size > 5
      _assign_fachinfo doc, sequence
    else
      remove_fachinfo sequence, opts
    end

    # assign registration number if really good match
    return if(cutoff < 2) # arbitrary value
    assign_registration sequence, data[:registration]
  rescue StandardError => error
    ODDB.logger.error('FachInfo') { error.message }
    retries ||= 1
    if(/ServerError/.match(error.message) && retries > 0)
      retries -= 1
      agent.history.clear
      @search_form = nil
      retry
    else
      @errors.push [ sequence.name.de, error.message, 
        error.backtrace.find { |ln| /pharmnet/.match ln }.to_s.strip, url ]
    end
  end
  def _assign_fachinfo(doc, sequence)
    ODDB.logger.debug('FachInfo') { 
      sprintf("Assigning Fachinfo to %s", sequence.name.de) 
    }
    if(previous = sequence.fachinfo.de)
      doc.previous_sources = [previous.previous_sources, previous.source]
    end
    sequence.fachinfo.de = doc
    @assigned += 1
    sequence.save
  end
  def assign_registration(sequence, registration)
    if(registration && sequence.code(:registration, 'EU') != registration)
      ODDB.logger.debug('FachInfo') { 
        sprintf('Assigning Registration-Number %s to %s', 
                registration, sequence.name.de) 
      }
      conflict = Drugs::Sequence.find_by_code(:value   => registration, 
                                              :type    => 'registration', 
                                              :country => 'EU')
      if(conflict && conflict != sequence)
        raise sprintf("Multiple assignment of Registration-Number %s (%s-%i/%s-%i)",
                      registration, sequence.name.de, sequence.odba_id, 
                      conflict.name.de, conflict.odba_id)
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
    suitable = suitable_data sequence, result
    max = 0
    relevances = suitable.collect { |data|
      rel = composition_relevance(sequence.active_agents, data[:composition])
      max = rel if rel > max
    }
    contenders = []
    relevances.each_with_index { |rel, idx|
      if(rel == max)
        contenders.push suitable.at(idx)
      end
    }
    contenders.sort_by { |data| data[:date] }.last
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
    srel = ngram_similarity(agent.substance.name.de, detail[:substance])
    drel + srel
  end
  def composition_relevance(agents, details)
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
      max = sum if sum > max
    }
    max / participants
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
    hrefs = page.links.inject([]) { |memo, link|
      if(/Fachinformation/i.match link.text)
        str = link.text[/(\d{2}\.){2}\d{4}/]
        memo.push [Date.new(*str.split('.').reverse.collect { |num| num.to_i}), 
          link.href]
      end
      memo
    }.sort
    if(oldest = hrefs.last) 
      data.update :date => oldest.first, :fachinfo => oldest.last
    end
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
        page = agent.get "http://gripsdb.dimdi.de" + href
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
    form.radiobuttons.find { |b| b.name == "WFTYP" && b.value == "YES" }.check
    link = page.links.find { |l| l.attributes["id"] == 'goME' }
    form.action = link.href
    form
  end
  def import(agent, sequences, opts = {:replace => false, :remove => false})
    sequences.each { |sequence|
      assign_fachinfo(agent, sequence, opts)
    }
    Util::Mail.notify_admins sprintf("%s: %s", Time.now.strftime('%c'),
                                     self.class), 
    [ "Assigned #@assigned Fachinfos",
      "Removed #@removed Fachinfos",
      "Errors: #{@errors.size}",
    ].concat(@errors.collect { |name, message, line, link| 
      sprintf "%s: %s (%s) -> http://gripsdb.pharmnet.de%s", 
              name, message, line, link
    })
  end
  def import_rtf(agent, url)
    file = agent.get url
    path = File.join @archive, File.basename(url)
    file.save path
    doc = FiParser.new.import StringIO.new(file.body)
    doc.chapters.shift
    ## ensure that chapter-headings are bold
    doc.chapters.each { |chapter|
      if((paragraph = chapter.paragraphs.first) \
         && (format = paragraph.formats.first))
        format.augment "b"
      end
    }
    doc.source = url
    doc
  end
  def ngram_similarity(str1, str2, n=5)
    str1 = u(str1).downcase.gsub(/[\s,.\-]/, '')
    str2 = u(str2).downcase.gsub(/[\s,.\-]/, '')
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
  def remove_fachinfo(sequence, opts)
    if opts[:remove] && sequence.fachinfo.de
      @removed += 1
      ODDB.logger.debug('FachInfo') { 
        sprintf('Removing Fachinfo from %s', sequence.name.de) 
      }
      sequence.fachinfo.de = nil
      sequence.save
    end
  end
  def result_page(form, term)
    form.field('term').value = term
    form.submit
  end
  def search(agent, term, minimal=nil)
    term = term.downcase
    @result_cache.fetch(term) do
      if(minimal = term[0,3])
        @result_cache.delete_if { |key, _|
          key < minimal
        }
      end
      @search_form ||= get_search_form agent
      details = agent.transact {
        page = result_page @search_form, term
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
  def suitable_data(sequence, selection)
    comparison = [
      sequence.name, 
      (gf = sequence.galenic_forms.first) && gf.description,
      (comp = sequence.company) && comp.name,
    ].collect { |ml| ml ? ml.de : '' }
    subcount = sequence.active_agents.size
    max = 0
    sums = []
    preselection = []
    selection.each_with_index { |data, idx|
      if(dists = _suitable_data(data, comparison, subcount))
        sum = dists.inject { |a,b| a+b }
        max = sum if sum > max
        sums.push sum
        preselection.push data
      end
    }
    result = []
    sums.each_with_index { |sum, idx|
      if sum == max
        result.push preselection[idx]
      end
    }
    result
  end
  def _suitable_data(data, comparison, subcount, cutoff=0.25)
    idx = 0
    raw = data[:data].dup
    
    ptrn = /(#{Regexp.escape(raw[1].to_s).gsub(' ', '|')}|\b\d+\s*m?g)\s*/i
    raw[0] = raw[0].gsub(ptrn, '')

    tabl = /([a-z]{4,})tab.*/i
    raw[1] = raw[1].to_s.gsub(tabl, '\1')
    comparison[1] = comparison[1].to_s.gsub(tabl, '\1')
    dists = raw.collect { |str|
      str = str.to_s
      other = comparison[idx].to_s
      idx += 1
      relevance = ngram_similarity str.gsub(@stop, ''), other.gsub(@stop, '')
      return if relevance < cutoff
      relevance
    }
    cdist = (subcount - data[:composition].size).abs
    dists.push(cdist) unless cdist > 0
  end
end
    end
  end
end
