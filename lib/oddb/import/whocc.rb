#!/usr/bin/env ruby
# Import::Whocc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

require 'oddb/drugs/atc'
require 'oddb/drugs/ddd'
require 'oddb/drugs/dose'
require 'oddb/import/xml'

module ODDB
  module Import
    class WhoccAtc < Xml
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
    class WhoccDdd < Xml
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
  end
end
