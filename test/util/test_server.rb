#!/usr/bin/env ruby
# Util::TestServer -- de.oddb.org -- 22.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/util/server'

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
        assert_match("test/util/test_server.rb:36:in `test_admin__3': some error", result)
      end
    end
  end
end
