#!/usr/bin/env ruby
# Import::TestExcel -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/import/dimdi'

module ODDB
  module Import
    class TestExcel < Test::Unit::TestCase
      def setup
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xls/fb010706.xls', @data_dir) 
        @input = open(@path)
        @import = Excel.new
      end
      def test_parse__and_cell
        workbook = @import.parse(@input)
        assert_instance_of(Spreadsheet::ParseExcel::Workbook, workbook)
        assert_equal(1, workbook.sheet_count)
        worksheet = workbook.worksheet(0)
        assert_instance_of(Spreadsheet::ParseExcel::Worksheet, worksheet)
        assert_equal(:text, worksheet.cell(1,0).type)
        assert_equal(u("PIROXICAM RATIO"), @import.cell(worksheet.row(1), 0))
        assert_equal(:numeric, worksheet.cell(1,5).type)
        assert_equal(20, @import.cell(worksheet.row(1), 5))
        assert_equal(:date, worksheet.cell(1,13).type)
        assert_equal(Date.new(2006,7), @import.cell(worksheet.row(1), 13))
      end
    end
  end
end
