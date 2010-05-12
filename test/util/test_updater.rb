#!/usr/bin/env ruby
# Util::TestUpdater -- de.oddb.org -- 05.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/util/updater'
require 'flexmock'
require 'stub/model'

module ODDB
  module Util
    class TestUpdater < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        ODDB.config.reset!
        @config = flexmock(ODDB.config)
        @var = File.expand_path('var', File.dirname(__FILE__))
        @data_dir = File.expand_path('data', File.dirname(__FILE__))
        @xls_dir = File.join(@var, 'xls')
        FileUtils.rm_r(@xls_dir) if(File.exist?(@xls_dir))
        @config.should_receive(:var).and_return(@var)
        @config.should_receive(:data_dir).and_return(@data_dir)
        @updater = Updater
        @errors = []
        ODDB.logger = flexmock('logger')
        ODDB.logger.should_receive(:error).and_return { |type, block|
          msg = block.call
          puts msg
          @errors.push msg
        }
        ODDB.logger.should_ignore_missing
      end
      def test_run
        today = Date.new(2006,10)
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(3)
        dimdi = flexmock(Import::Dimdi)
        dimdi.should_receive(:current_date).and_return today
        dimdi_files = %w{wirkkurz_011006.xls darform_011006.xls fb_011006.xls}
        download = StringIO.new('downloaded from dimdi')
        dimdi.should_receive(:download).times(3).and_return do |file, block|
          assert_equal dimdi_files.shift, file
          block.call download
        end
        flexmock(Import::Dimdi::GalenicForm).new_instances.should_receive(:import).with(download).times(1).and_return []
        flexmock(Import::Dimdi::Product).new_instances.should_receive(:import).with(download).times(1).and_return []
        flexmock(Import::Dimdi::Substance).new_instances.should_receive(:import).with(download).times(1).and_return []
        job_dir = File.join ODDB.config.oddb_dir, 'jobs'
        log_dir = File.join ODDB.config.oddb_dir, 'log'
        cmds = %w{import_gkv import_pharmnet import_whocc}
        flexmock(IO).should_receive(:popen).and_return do |popen, block|
          cmd = cmds.shift
          assert_equal "#{job_dir}/#{cmd} log_file=#{log_dir}/#{cmd}", popen
        end
        @updater.run(today)
      end
      def test_run__errors
        today = Date.new(2006,10)
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(0)
        dimdi = flexmock(Import::Dimdi)
        dimdi.should_receive(:current_date).and_return today
        dimdi_files = %w{wirkkurz_011006.xls darform_011006.xls fb_011006.xls}
        download = StringIO.new('downloaded from dimdi')
        dimdi.should_receive(:download).times(1).and_return do |file, block|
          assert_equal dimdi_files.shift, file
          raise "connection error"
        end
        job_dir = File.join ODDB.config.oddb_dir, 'jobs'
        log_dir = File.join ODDB.config.oddb_dir, 'log'
        cmds = %w{import_gkv import_pharmnet import_whocc}
        flexmock(IO).should_receive(:popen).and_return do |popen, block|
          cmd = cmds.shift
          assert_equal "#{job_dir}/#{cmd} log_file=#{log_dir}/#{cmd}", popen
        end
        assert_raises RuntimeError do
          @updater.run(today)
        end
      end
      def test_run__later_errors
        today = Date.new(2006,10)
        flexmock(Util::Mail).should_receive(:notify_admins)\
          .with(String, Array).times(3)
        dimdi = flexmock(Import::Dimdi)
        dimdi.should_receive(:current_date).and_return today
        dimdi_files = %w{wirkkurz_011006.xls darform_011006.xls fb_011006.xls}
        download = StringIO.new('downloaded from dimdi')
        dimdi.should_receive(:download).times(3).and_return do |file, block|
          assert_equal dimdi_files.shift, file
          block.call download
        end
        flexmock(Import::Dimdi::GalenicForm).new_instances.should_receive(:import).with(download).times(1).and_return do raise 'import error' end
        flexmock(Import::Dimdi::Product).new_instances.should_receive(:import).with(download).times(1).and_return do raise 'import error' end
        flexmock(Import::Dimdi::Substance).new_instances.should_receive(:import).with(download).times(1).and_return do raise 'import error' end
        job_dir = File.join ODDB.config.oddb_dir, 'jobs'
        log_dir = File.join ODDB.config.oddb_dir, 'log'
        cmds = %w{import_gkv import_pharmnet import_whocc}
        flexmock(IO).should_receive(:popen).and_return do |popen, block|
          cmd = cmds.shift
          assert_equal "#{job_dir}/#{cmd} log_file=#{log_dir}/#{cmd}", popen
        end
        assert_nothing_raised do
          @updater.run(today)
        end
      end
    end
  end
end
