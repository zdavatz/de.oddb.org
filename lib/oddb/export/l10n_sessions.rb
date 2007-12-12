#!/usr/bin/env ruby
# Export::SessionStub -- de.oddb.org -- 11.12.2007 -- hwyss@ywesee.com

require 'oddb/html/util/lookandfeel'
require 'oddb/html/util/session'

module ODDB
  module Export
    class SessionStub
      attr_reader :flavor, :http_protocol, :default_language, :server_name
      attr_accessor :language, :lookandfeel
      def initialize
        @flavor = Html::Util::Session::DEFAULT_FLAVOR
        @http_protocol = 'http'
        @default_language = 'de'
        @server_name = ODDB.config.server_name
      end
      def method_missing(*args)
      end
    end
    def Export.l10n_sessions(&block)
      stub = SessionStub.new
      Html::Util::Lookandfeel::DICTIONARIES.each_key { |lang|
        stub.language = lang
        stub.lookandfeel = Html::Util::Lookandfeel.new(stub)
        block.call(stub)
      }
    end
  end
end
