#!/usr/bin/env ruby
# Util::TestMail -- de.oddb.org -- 06.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/util/mail'
require 'flexmock'

module ODDB
  module Util
    class TestMail < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @config = ODDB.config
      end
      def test_notify_admins
        @config.admins = ['admin1@ywesee.com', 'admin2@ywesee.com']
        smtp = flexmock('SMTP')
        flexstub(Net::SMTP).should_receive(:new).with('localhost')\
          .times(1).and_return(smtp)
        smtp.should_receive(:start).times(1).and_return { |blk|
          smtp.should_receive(:sendmail)\
            .with(String, 'update@oddb.org', 'admin1@ywesee.com')\
            .times(1).and_return { assert(true) }
          smtp.should_receive(:sendmail)\
            .with(String, 'update@oddb.org', 'admin2@ywesee.com')\
            .times(1).and_return { assert(true) }
          blk.call
        }
        Mail.notify_admins('Test-Mail', 
                           [ "This test-mail was sent from",
                             sprintf("%s:%s", __FILE__, __LINE__),
                             "TestMail#test_notify_admins"])
      end
    end
  end
end
