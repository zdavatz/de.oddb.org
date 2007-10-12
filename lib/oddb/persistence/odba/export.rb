#!/usr/bin/env ruby
# Export -- de.oddb.org -- 10.10.2007 -- hwyss@ywesee.com

require 'odba'
require 'oddb/export/yaml'

module ODBA
  class Stub
    def to_yaml(*args)
      odba_instance.to_yaml(*args)
    end
  end
  module Persistable
    unless(instance_methods.include?('__odba_to_yaml_properties__'))
      alias :__odba_to_yaml_properties__ :to_yaml_properties
    end
    def to_yaml_properties
      (super - odba_exclude_vars).reject { |name| 
        /^@odba_/.match name}
    end
  end
end
module ODDB
  class Model
    def oid
      @odba_id
    end
  end
end
