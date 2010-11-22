#!/usr/bin/env ruby
# Business::TestGrantDownload -- de.oddb.org -- 22.11.2011 -- mhatakeyama@ywesee.com


$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/business/grant_download'

module ODDB
  module Business
    class TestGrantDownload < Test::Unit::TestCase
      def setup
        @user = GrantDownload.new('aaa@bbb.ccc')
        @user.grant_download('test1.dat', Time.local(1999,12,31))
        @user.grant_download('test2.dat', Time.local(2999,12,31))
      end
      def test_grant_download
        assert_equal(@user.grant_list.length, 2) 
        assert_equal(@user.grant_list['test1.dat'], Time.local(1999,12,31))
      end
      def test_expired?
        assert_equal(@user.expired?('test1.dat'), true)
        assert_equal(@user.expired?('test2.dat'), false)
        assert_equal(@user.expired?('test3.dat'), true)
      end
    end
  end
end
