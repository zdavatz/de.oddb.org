#!/usr/bin/env ruby
# Import::PharmNet -- de.oddb.org -- 15.10.2007 -- hwyss@ywesee.com

require 'oddb/import/import'
require 'oddb/import/rtf'

module ODDB
  module Import
    module PharmNet
class FiParser < Rtf
  def identify_chapter buffer
    name = case buffer 
           when /^10\.?\s*Stand/i then 'date'
           when /^11\.?\s*(Verschreibung|Verkauf)/i then 'sale_limitation'
           when /^1\.?\s*Bezeichnung/i then 'name'
           when /^2\.?\s*(Qualitative|Zusammensetzung)/i  then 'composition'
           when /^3\.?\s*Darreichung/i  then 'galenic_form'
           when /^4\.1\.?\s*Anwendung/i then 'indications'
           when /^4\.2\.?\s*Dosierung/i then 'dosage'
           when /^4\.3\.?\s*Gegenanzeigen/i then 'counterindications'
           when /^4\.4\.?\s*(Besondere\s+)?Warnhinweise/i then 'precautions'
           when /^4\.5\.?\s*Wechselwirkungen/i then 'interactions'
           when /^4\.6\.?\s*(Anwendung|Schwangerschaft)/i then 'pregnancy'
           when /^4\.7\.?\s*Auswirkung/i then 'driving_ability'
           when /^4\.8\.?\s*Nebenwirkungen/i then 'unwanted_effects'
           when /^4\.9\.?\s*Überdosierung/i then 'overdose'
           when /^4\.?\s*Klinisch/i then 'clinical'
           when /^5\.1\.?\s*Pharmakodynamisch/i then 'pharmacodynamics'
           when /^5\.2\.?\s*Pharmakokinetisch/i then 'pharmacokinetics'
           when /^5\.3\.?\s*Präklinisch/i then 'preclinicals'
           when /^5\.?\s*Pharmakologisch/i then 'pharmacology'
           when /^6\.1\.?\s*(Liste|Hilfsstoffe?)/i then 'excipients'
           when /^6\.2\.?\s*Inkompatibilitäten/i then 'incompatibilities'
           when /^6\.3\.?\s*(Dauer|Haltbarkeit)/i then 'shelf_life'
           when /^6\.4\.?\s*(Besondere|Lagerung|Aufbewahrung)/i then 'storage'
           when /^6\.5\.?\s*(Art|Behältnis)/i then 'packaging'
           when /^6\.6\.?\s*(Besondere|Hinweis|Entsorgung)/i then 'disposal'
           when /^6\.?\sPharmazeutisch/i then 'pharmaceutic'
           when /^7\.?\s*(Name|Pharmazeutischer|Inhaber)/i  then 'company'
           when /^8\.?\s*Zulassung/i then 'registration'
           when /^9\.?\s*Datum/i then 'registration_date'
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
  def import_rtf(agent, url)
    file = agent.get url
    doc = FiParser.new.import StringIO.new(file.body)
    doc.chapters.shift
    ## ensure that chapter-headings are bold
    doc.chapters.each { |chapter|
      if((paragraph = chapter.paragraphs.first) \
         && (format = paragraph.formats.first))
        format.augment "b"
      end
    }
    doc
  end
end
    end
  end
end
