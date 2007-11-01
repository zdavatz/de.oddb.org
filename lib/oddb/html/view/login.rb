#!/usr/bin/env ruby
# Html::View::Login -- de.oddb.org -- 26.10.2007 -- hwyss@ywesee.com

require 'htmlgrid/pass'
require 'oddb/html/view/drugs/template'
require 'oddb/html/view/snapback'

module ODDB
  module Html
    module View
class LoginForm < HtmlGrid::Form
  COMPONENTS = {
    [0,0] =>  :email,
    [0,1] =>  :pass,
    [1,2] =>  :submit,
  }
  EVENT = :login
  FORM_NAME = 'login'
  LABELS = true
  SYMBOL_MAP = {
    :pass =>  HtmlGrid::Pass, 
  }
end
class LoginComposite < HtmlGrid::DivComposite
  include Snapback
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => "login", 
    [0,2] => LoginForm,
  }
  CSS_ID_MAP = [ 'snapback', 'title' ]
end
class Login < Template
  CONTENT = LoginComposite
end
    end
  end
end
