require 'oddb/html/state/global_predefine'
require 'oddb/html/view/download'

module ODDB
  module Html
    module State
class Download < State::Global
	VIEW = View::Download
	VOLATILE = true
end
    end
	end
end
