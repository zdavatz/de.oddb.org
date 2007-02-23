#!/usr/bin/env ruby
# Import::Excel -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

require 'parseexcel/parseexcel'
require 'oddb/import/import'

module ODDB
  module Import
    class Excel < Import
      attr_reader :report
      def cell(row, idx)
        if(cell = row[idx])
          case cell.type
          when :date
            cell.date
          when :numeric
            cell.to_f
          else
            u(cell.to_s('utf8')).strip
          end
        end
      end
      def import(io)
        workbook = parse(io)
        import_worksheet(workbook.worksheet(0))
        postprocess()
        report
      end
      def import_worksheet(worksheet)
        worksheet.each(@skip_rows) { |row|
          import_row(row)
        }
      end
      def parse(io)
        Spreadsheet::ParseExcel.parse(io)
      end
    end
    class DatedExcel < Excel
      def initialize(date = Date.today)
        super()
        @date = date
      end
    end
  end
end
