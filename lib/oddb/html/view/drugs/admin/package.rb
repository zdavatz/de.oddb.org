#!/usr/bin/env ruby
# Html::View::Drugs::Admin::Package -- de.oddb.org -- 29.10.2007 -- hwyss@ywesee.com

require 'oddb/html/view/drugs/package'

module ODDB
  module Html
    module View
      module Drugs
        module Admin
class PackageForm < HtmlGrid::Form
  EVENT = :update
  COMPONENTS = {
    [0,0] => :fi_url, 
    [1,1] => :submit, 
  }
  LABELS = true
end
class PackageComposite < Drugs::PackageComposite
  COMPONENTS = {
    [0,0] => :snapback, 
    [0,1] => InlineSearch, 
    [0,2] => :name,
    [0,3] => PackageInnerComposite,
    [0,4] => PackageForm,
    [0,5] => :parts,
  }
  CSS_MAP = { 0 => 'before-searchbar', 5 => 'divider' }
end
class Package < Drugs::Package
  CONTENT = PackageComposite
end
        end
      end
    end
  end
end
