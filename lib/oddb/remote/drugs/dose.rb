#!/usr/bin/env ruby
# Dose -- de.oddb.org -- 16.02.2007 -- hwyss@ywesee.com

## in remote, Dose is in a different namespace
require 'oddb/drugs/dose'
module ODDB
  Dose = Drugs::Dose
end
