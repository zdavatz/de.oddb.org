#!/usr/bin/env ruby
# Util::TestServer -- de.oddb.org -- 22.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/util/server'
require 'oddb/business/grant_download'

module ODDB
  module Util
    class TestServer < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        ODDB.logger = flexmock('logger')
        @app = flexmock('app')
        @server = Server.new(@app)
      end
      def test_admin__1
        @app.should_receive(:foo).and_return(true)
        result = ''
        t = @server._admin('foo', result)
        assert_instance_of(Thread, t)
        t.join
        assert_equal('true', result)
      end
      def test_admin__2
        @app.should_receive(:foo).and_return('x'*201)
        result = ''
        t = @server._admin('foo', result)
        assert_instance_of(Thread, t)
        t.join
        assert_equal('String', result)
      end
      def test_admin__3
        @app.should_receive(:foo).and_return { raise "some error" }
        ODDB.logger.should_receive(:error).times(3).and_return { |key, pr|
          assert_equal('admin', key)
        }
        result = ''
        t = @server._admin('foo', result)
        assert_instance_of(Thread, t)
        t.join
        assert_match("test/util/test_server.rb:37:in `test_admin__3': some error", result)
      end
      def test_grant_download__1
        # Case: Usage 
        usage = "Usage:\n" +
          "  Set  grant: grant_download 'email address', 'file', Time.local(20yy,mm,dd)\n" +
          "  Show grant: grant_download 'email address'\n"
        assert_equal(usage, @server.grant_download)
      end
      def test_grant_download__2
        # Case: No registration
        flexstub(ODDB::Business::GrantDownload).should_receive(:find_by_email).and_return(nil)
        assert_equal('No registration for aaa@bbb.ccc', @server.grant_download('aaa@bbb.ccc'))
      end
      def test_grant_download__3
        # Case: Find a registration case
        hash = {
          'test1.dat' => Time.local(2000,1,1),
          'test2.dat' => Time.local(2001,1,1)
        }
        flexstub(ODDB::Business::GrantDownload).should_receive(:find_by_email).and_return do 
          flexmock do |user|
            user.should_receive(:grant_list).and_return(hash)
            user.should_receive(:uid).and_return('123')
          end
        end
        result = "grant list(total:2): odba_id: 123\n20010101, test2.dat\n20000101, test1.dat"
        assert_equal(result, @server.grant_download('aaa@bbb.ccc'))
      end
      def test_grant_download__3
        # Case: Registration
        email = 'aaa@bbb.ccc'
        file  = 'test.dat'
        expiry_time = Time.local(2010,12,31)
        flexstub(ODDB::Business::GrantDownload) do |klass|
          klass.should_receive(:find_by_email).with(email)
          klass.should_receive(:new).with(email).and_return do 
            flexmock('grant_download object') do |user|
              user.should_receive(:grant_download).with(file, expiry_time)
              user.should_receive(:save)
            end
          end
        end
        ODDB.config.http_server = 'http://de.oddb.org'
        result = "http://de.oddb.org/de/temp/grant_download/email/aaa@bbb.ccc/file/test.dat"
        assert_equal(result, @server.grant_download('aaa@bbb.ccc', 'test.dat', Time.local(2010,12,31)))
      end
    end
  end
end
