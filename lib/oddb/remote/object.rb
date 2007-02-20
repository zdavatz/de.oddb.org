#!/usr/bin/env ruby
# Remote::Object -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

require 'iconv'

module ODDB
  module Remote
    class Object
      @@iconv = Iconv.new('utf8//IGNORE//TRANSLIT', 'latin1')
      def initialize(source, remote)
        @source = source
        @remote = remote
        @cache = {}
      end
=begin
      def method_missing(*args, &block)
        @cache[args] ||= @remote.send(*args, &block)
      rescue
        "remote: #{self.class}##{args.join(', ')}"
      end
=end
      def uid
        sprintf("%i.%s", @source, @remote.__drbref)
      end
    end
  end
end
