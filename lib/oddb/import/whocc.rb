#!/usr/bin/env ruby
# Import::Whocc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'oddb/drugs/atc'
require 'oddb/drugs/ddd'
require 'oddb/drugs/dose'
require 'oddb/import/xml'

module ODDB
  module Import
    module Whocc
class Atc < Xml
  def import_document(doc)
    REXML::XPath.each(doc, '//rs:data/rw:row', 
      "rs" => 'urn:schemas-microsoft-com:rowset',
      "rw" => '#RowsetSchema') { |row|
      code = row.attributes['ATCCode']
      atc = Drugs::Atc.find_by_code(code) || Drugs::Atc.new(code)
      atc.name.de = row.attributes['Name']
      atc.save
    }
  end
end
class Ddd < Xml
  UNIT_REPLACEMENTS = {
    'TSD E' => 'TsdI.E.',
    'MIO E' => 'MioI.E.',
  }
  def import_document(doc)
    REXML::XPath.each(doc, '//rs:data/rw:row', 
      "rs" => 'urn:schemas-microsoft-com:rowset',
      "rw" => '#RowsetSchema') { |row|
      attrs = row.attributes
      code = attrs['ATCCode']
      atc = Drugs::Atc.find_by_code(code) || Drugs::Atc.new(code)
      adm = attrs['AdmCode']
      comment = attrs['DDDComment']
      ddd = atc.ddds.find { |candidate|
        adm == candidate.administration \
          && comment == candidate.comment
      } || Drugs::Ddd.new(adm)
      ddd.comment = comment
      unit = attrs['UnitType']
      unit = UNIT_REPLACEMENTS.fetch(unit, unit)
      ddd.dose = Drugs::Dose.new(attrs['DDD'], unit)
      ddd.atc = atc
      ddd.save
      atc.save
    }
  end
end
class Guidelines < Import
  attr_reader :codes
  class CodeHandler
    ATC_TOP_LEVEL = %w{A B C D G H J L M N P R S V}
    attr_reader :queue, :visited
    def initialize
      @queue = ATC_TOP_LEVEL.dup
      @visited = []
    end
    def push(code)
      unless((@queue + @visited).include?(code))
        @queue.push(code)
      end
    end
    def shift
      code = @queue.shift
      @visited.push(code)
      code
    end
  end
  @@query_re = /query=([A-Z0-9]+)/
  def initialize
    super
    @url = 'http://www.whocc.no/atcddd/database/index.php'
    @codes = CodeHandler.new
    @count = 0
    @created = 0
    @ddd_guidelines = 0
    @guidelines = 0
  end
  def extract_text(node)
    unless(node.containers.any? { |br| br.name != 'br' })
      node.inner_html.gsub(/\s+/, ' ').gsub(/\s*<br\s*\/?>\s*/, "\n")
    end
  end
  def import(agent)
    login(agent)
    while(code = @codes.shift)
      @count += 1
      import_code(agent, code)
    end
    report
  end
  def import_atc(code, link)
    name = capitalize_all(link.inner_text.to_s)
    atc = Drugs::Atc.find_by_code(code) || Drugs::Atc.new(code)
    unless(atc.name.en == name)
      @created += 1
      atc.name.en = name
      atc.save
    end
    atc
  end
  def import_code(agent, get_code)
    page = agent.get(@url + "?query=%s&showdescription=yes" % get_code)
    (page/"//b/a").each { |link|
      if(match = @@query_re.match(link.attributes['href']))
        code = match[1] 
        if(code == get_code)
          atc = import_atc(code, link) 
          import_guidelines(atc, link) && atc.save
        end
        @codes.push(code)
      end
    }
    (page/"//ul//a").each { |link|
      if(match = @@query_re.match(link.attributes['href']))
        code = match[1] 
        import_atc(code, link)
      end
    }
  end
  def import_ddd_guidelines(atc, table)
    guidelines = (table/'td').collect { |td| 
      extract_text(td) }.join if(table)
    if(atc.ddd_guidelines.en != guidelines)
      @ddd_guidelines += 1
      atc.ddd_guidelines.en = guidelines
      modified = true
    end
  end
  def import_guidelines(atc, link)
    node = link.parent
    while(node.name != 'p')
      node = node.next_sibling
    end
    tables = (node/'/table').remove
    table = tables.find { |tab| 
      tab.respond_to?(:attributes) \
        && tab.attributes['bgcolor'] == '#cccccc'
    }
    modified = import_ddd_guidelines(atc, table)
    guidelines = extract_text(node)
    if(atc.guidelines.en != guidelines)
      @guidelines += 1
      modified = true
      atc.guidelines.en = guidelines
    end
    modified
  end
  def login(agent)
    msg = "Please configure your access to #@url in ODDB.config.credentials['whocc']"
    credentials = ODDB.config.credentials['whocc'] or raise msg
    page = agent.get(@url)
    form = page.form(nil) # unnamed form
    form.username = credentials['username']
    form.password = credentials['password']
    agent.submit(form)
  end
  def report
    [
      sprintf("Imported %3i ATC-Codes", @count),
      sprintf("Updated  %3i English descriptions", @created),
      sprintf("Updated  %3i Guidelines", @guidelines),
      sprintf("Updated  %3i DDD-Guidelines", @ddd_guidelines),
    ]
  end
end
    end
  end
end
