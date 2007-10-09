#!/usr/bin/env ruby
# Util::TestExporter -- de.oddb.org -- 03.10.2007 -- hwyss@ywesee.com


$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/util/exporter'
require 'flexmock'

module ODDB
  module Util
    class TestExporter < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @data_dir = File.expand_path('var/xls', File.dirname(__FILE__))
      end
      def test_run
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .and_return { |subj, body| flunk(body.join("\n")) }
        klass = flexmock(Export::Xls::ComparisonDeCh)
        ODDB.config.remote_databases = []
        assert_nothing_raised {
          Exporter.run(Date.new(2007))
        }
        exp = flexmock('exp')
        path = File.join(@data_dir, 'chde.xls')
        remote = flexmock('remote')
        drb = DRb.start_service('druby://localhost:0', remote)
        klass.should_receive(:new).and_return(exp)
        exp.should_receive(:export).and_return { |uri, file|
          assert_equal(drb.uri, uri)
          assert_instance_of(File, file)
          assert_equal(path, file.path)
        }
        ODDB.config.remote_databases = [drb.uri]
        remote.should_receive(:remote_export).and_return { |file, block| 
          assert_equal("chde.xls", file)
          block.call(path) }
        Exporter.run(Date.new(2007))
      end
      def test_remote_export_chde
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .and_return { |subj, body| flunk(body.join("\n")) }
        klass = flexmock(Export::Xls::ComparisonDeCh)
        ODDB.config.remote_databases = []
        assert_nothing_raised {
          Exporter.remote_export_chde
        }
        exp = flexmock('exp')
        path = File.join(@data_dir, 'chde.xls')
        remote = flexmock('remote')
        drb = DRb.start_service('druby://localhost:0', remote)
        klass.should_receive(:new).and_return(exp)
        exp.should_receive(:export).and_return { |uri, file|
          assert_equal(drb.uri, uri)
          assert_instance_of(File, file)
          assert_equal(path, file.path)
        }
        ODDB.config.remote_databases = [drb.uri]
        remote.should_receive(:remote_export).and_return { |file, block| 
          assert_equal("chde.xls", file)
          block.call(path) }
        Exporter.remote_export_chde
      end
      def test_on_monthday
        called = false
        Exporter.on_monthday(3, Date.new(2007,10)) {
          called = true
        }
        assert_equal(false, called, "Should not have called the block: 3 != 1")
        Exporter.on_monthday(3, Date.new(2007,10,3)) {
          called = true
        }
        assert_equal(true, called, "Should have called the block: 3 == 3")
        called = false
        Exporter.on_monthday(Date.today.day) {
          called = true
        }
        assert_equal(true, called, 
                     "Should have called the block: defaults to today")
      end
    end
  end
end
