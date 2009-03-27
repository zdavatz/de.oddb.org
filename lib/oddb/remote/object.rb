#!/usr/bin/env ruby
# Remote::Object -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

module ODDB
  module Remote
    class Object
      attr_reader :source
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
      class << self
        def delegate(*args)
          args.each { |arg|
            define_method(arg) { 
              var = "@#{arg}"
              instance_variable_get(var) \
                || instance_variable_set(var, @remote.send(arg))
            }
          }
        end
      end
    end
  end
end
