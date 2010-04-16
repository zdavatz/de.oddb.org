require 'mechanize'
require 'oddb/drugs'
require 'oddb/import/importer'

module ODDB
  module Import
class Whocc < Importer
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
      @visited.push(code) if code
      code
    end
  end
  @@query_re = /code=([A-Z0-9]+)/
  UNIT_REPLACEMENTS = {
    'TSD E' => 'TsdI.E.',
    'MIO E' => 'MioI.E.',
  }
  def initialize
    super
    @url = 'http://www.whocc.no/atc_ddd_index/'
    @codes = CodeHandler.new
    @count = 0
    @created = 0
    @ddd_guidelines = 0
    @guidelines = 0
  end
  def extract_text(node)
    unless(node.children.any? { |br| br.element? && br.name != 'br' })
      html = node.inner_html
      if RUBY_VERSION < '1.9'
        html.gsub! /\240/, ''
      end
      html.gsub(/\s+/, ' ').gsub(/\s*<br\s*\/?>\s*/, "\n").strip
    end
  end
  def import(agent=Mechanize.new)
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
    page = agent.get(@url + "?code=%s&showdescription=yes" % get_code)
    (page/"//b/a").each do |link|
      if(match = @@query_re.match(link.attributes['href']))
        code = match[1] 
        if(code == get_code)
          atc = import_atc(code, link) 
          import_guidelines(atc, link) && atc.save
        end
        @codes.push(code)
      end
    end
    (page/"//ul//a").each do |link|
      if(match = @@query_re.match(link.attributes['href']))
        code = match[1] 
        atc = import_atc(code, link)
        import_ddds atc, link.parent.parent
      end
    end
  end
  def import_ddds(atc, row)
    code = nil
    begin
      code, link, dose, unit, adm, comment = row.children.collect do |td|
        extract_text(td).to_s end
      comment = comment.empty? ? nil: comment
      return unless code.empty? || code == atc.code
      unless dose.empty?
        ddd = atc.ddds.find do |candidate|
          adm == candidate.administration \
            && comment == candidate.comment
        end
        ddd  ||= Drugs::Ddd.new(adm)
        ddd.comment = comment
        unit = UNIT_REPLACEMENTS.fetch(unit, unit)
        ddd.dose = Drugs::Dose.new(dose, unit)
        ddd.atc = atc
        ddd.save
        atc.save
      end
    end while row = row.next_sibling
  end
  def import_ddd_guidelines(atc, table)
    guidelines = (table/'td').collect do |td|
      extract_text(td) end.join if(table)
    if(atc.ddd_guidelines.en != guidelines)
      @ddd_guidelines += 1
      atc.ddd_guidelines.en = guidelines
      modified = true
    end
  end
  def import_guidelines(atc, link)
    node = link.parent
    while(node.name != 'p')
      node = node.next_sibling or return
    end
    ## nokogiri fixes the faulty html of whocc.no, and moves the table element
    #  out of the p-container.
    table = node.next_sibling
    modified = false
    if table.name == 'table' && table[:bgcolor] == '#cccccc'
      modified = import_ddd_guidelines(atc, table)
    end
    guidelines = extract_text(node)
    if(atc.guidelines.en != guidelines)
      @guidelines += 1
      modified = true
      atc.guidelines.en = guidelines
    end
    modified
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
