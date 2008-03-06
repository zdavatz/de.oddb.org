#!/usr/bin/env ruby
# Html::View::Drugs::Admin::Package -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module View
      module Drugs
        module Admin
class PackageForm < Drugs::PackageInnerComposite
  include HtmlGrid::FormMethods
  COLSPAN_MAP = {
    [1,7] => 3,
  }
  COMPONENTS = {
    [0,0] => :name, 
    ## google's third parameter ensures that its link is written before 
    #  the name - this allows a float: right in css to work correctly
    [1,0,0] => :google,  
    [2,0] => :code_pzn, 
    [0,1] => :company, 
    [2,1] => :atc,
    [0,2] => :price_public, 
    [2,2] => :price_festbetrag,
    [0,3] => :code_festbetragsstufe,
    [2,3] => :code_festbetragsgruppe,
    [0,4] => :code_zuzahlungsbefreit,
    [2,4] => :equivalence_factor,
    [0,5] => :code_prescription,
    [1,6,0] => :fachinfo_link,
    [1,6,1] => :patinfo_link,
    [0,7] => :fi_url,
    [1,8] => :submit, 
  }
  COMPONENT_CSS_MAP = {
    [1,7] => 'url',
  }
  EVENT = :update
  SYMBOL_MAP = {
    :fi_url => HtmlGrid::InputText,
  }
end
class PackageComposite < Drugs::PackageComposite
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => PackageForm,
    [0,4] => :parts,
  }
end
class Package < Drugs::Package
  CONTENT = PackageComposite
end
        end
      end
    end
  end
end
