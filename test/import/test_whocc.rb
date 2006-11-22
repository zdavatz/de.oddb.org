#!/usr/bin/env ruby
# Import::TestWhoccAtc -- de.oddb.org -- 17.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/import/whocc'
require 'stub/model'

module ODDB
  module Drugs
    class Atc < Model
      simulate_database(:code)
    end
    class Ddd < Model
      simulate_database
    end
  end
  module Import
    class TestWhoccAtc < Test::Unit::TestCase
      def setup
        Drugs::Atc.instances.clear
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xml/ATC_2006.xml', @data_dir) 
        @import = WhoccAtc.new
      end
      def test_import
        assert_equal([], Drugs::Atc.instances)
        input = open(@path)
        @import.import(input) 
        assert_equal(23, Drugs::Atc.instances.size)
        atc = Drugs::Atc.instances.first
        expected = [ 'A', 'A01', 'A01A', 'A01AA', 'A01AA01', 'A01AA30',
          'A01AB', 'A01AB02', 'V', 'V01', 'V01A', 'V01AA', 'V01AA01',
          'V03', 'V03A', 'V03AB', 'V03AB01', 'V03AZ01', 'V04', 'V04C',
          'V04CC04', 'V04CD', 'V04CD05', ]
        codes = Drugs::Atc.instances.collect { |atc| atc.code }
        assert_equal(expected, codes)
        assert_equal('ALIMENTÄRES SYSTEM UND STOFFWECHSEL',
                     Drugs::Atc.instances.at(0).name.de)
        assert_equal('STOMATOLOGIKA',
                     Drugs::Atc.instances.at(1).name.de)
        assert_equal('Somatorelin',
                     Drugs::Atc.instances.at(22).name.de)

        # do it again, nothing should change
        input = open(@path)
        @import.import(input) 
        assert_equal(23, Drugs::Atc.instances.size)
        atc = Drugs::Atc.instances.first
        codes = Drugs::Atc.instances.collect { |atc| atc.code }
        assert_equal(expected, codes)
        assert_equal('ALIMENTÄRES SYSTEM UND STOFFWECHSEL',
                     Drugs::Atc.instances.at(0).name.de)
        assert_equal('STOMATOLOGIKA',
                     Drugs::Atc.instances.at(1).name.de)
        assert_equal('Somatorelin',
                     Drugs::Atc.instances.at(22).name.de)
      end
    end
    class TestWhoccDdd < Test::Unit::TestCase
      def setup
        Drugs::Atc.instances.clear
        Drugs::Ddd.instances.clear
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @path = File.expand_path('xml/ATC_2006_ddd.xml', @data_dir) 
        @import = WhoccDdd.new
      end
      def test_import
        assert_equal([], Drugs::Atc.instances)
        assert_equal([], Drugs::Ddd.instances)
        input = open(@path)
        @import.import(input) 
        assert_equal(2, Drugs::Atc.instances.size)
        assert_equal(3, Drugs::Ddd.instances.size)
        atc1 = Drugs::Atc.instances.at(0)
        atc2 = Drugs::Atc.instances.at(1)
        ddds = Drugs::Ddd.instances
        assert_equal(ddds[0,1], atc1.ddds)
        assert_equal(ddds[1,2], atc2.ddds)
        ddd1 = atc2.ddds.first
        ddd2 = atc2.ddds.last
        assert_equal('O', ddd1.administration)
        assert_equal(Drugs::Dose.new(7, 'mg'), ddd1.dose)
        assert_equal('mikrokristall. Substanz', ddd1.comment)
        assert_equal(atc2, ddd1.atc)
        assert_equal('O', ddd2.administration)
        assert_equal(Drugs::Dose.new(10, 'mg'), ddd2.dose)
        assert_nil(ddd2.comment)
        assert_equal(atc2, ddd2.atc)
        codes = Drugs::Atc.instances.collect { |atc| atc.code }

        # do it again, nothing should change
        input = open(@path)
        @import.import(input) 
        assert_equal(2, Drugs::Atc.instances.size)
        assert_equal(3, Drugs::Ddd.instances.size)
        atc1 = Drugs::Atc.instances.at(0)
        atc2 = Drugs::Atc.instances.at(1)
        ddds = Drugs::Ddd.instances
        assert_equal(ddds[0,1], atc1.ddds)
        assert_equal(ddds[1,2], atc2.ddds)
        ddd1 = atc2.ddds.first
        ddd2 = atc2.ddds.last
        assert_equal('O', ddd1.administration)
        assert_equal(Drugs::Dose.new(7, 'mg'), ddd1.dose)
        assert_equal('mikrokristall. Substanz', ddd1.comment)
        assert_equal(atc2, ddd1.atc)
        assert_equal('O', ddd2.administration)
        assert_equal(Drugs::Dose.new(10, 'mg'), ddd2.dose)
        assert_nil(ddd2.comment)
        assert_equal(atc2, ddd2.atc)
        codes = Drugs::Atc.instances.collect { |atc| atc.code }
      end
    end
  end
end
