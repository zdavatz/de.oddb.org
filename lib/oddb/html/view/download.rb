require 'htmlgrid/passthru'

module ODDB
  module Html
    module View
class Download < HtmlGrid::PassThru
  def to_html(context)
    @session.passthru(@model)
    ''
  end
end
    end
  end
end
