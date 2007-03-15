#!/usr/bin/env ruby
# Html::State::Drugs::Result -- de.oddb.org -- 07.11.2006 -- hwyss@ywesee.com

require 'oddb/html/state/global_predefine'
require 'oddb/html/util/sort'
require 'oddb/html/view/drugs/result'

module ODDB
  module Html
    module State
      module Drugs
class Result < Drugs::Global
  class Paginator
    attr_accessor :page
    attr_reader :pages, :model
    def initialize(model)
      @model = model
      @page = 0
      @pages = [0]
    end
    def collect!(&block)
      @model.collect!(&block)
      self
    end
    def each(&block)
      max = @pages.length - 1
      range = if(@page >= max) 
                @pages[max]..-1
              else
                @pages[@page]...@pages[@page.next]
              end
      @model[range].each(&block)
    end
    def method_missing(key, *args, &block)
      @model.send(key, *args, &block)
    end
    def next_page!
      @page = @pages.size
      @pages.push(@model.size)
      @page
    end
    def page_count
      @pages.size
    end
  end
  include Util::PackageSort
  VIEW = View::Drugs::Result
  def init
    partition!
    sort_by(:price_public)
    sort_by(:size)
    sort_by(:active_agents)
    sort_by(:product)
    paginate
    sort
  end
  def direct_event
    [:search, :query, @model.query, :dstype, @model.dstype]
  end
  def paginate
    if(page = @session.user_input(:page))
      @model.page = page
    end
  end
  def partition!
    atcs = {}
    @model = Paginator.new(@model)
    @model.total = @model.size
    while(package = @model.shift)
      code = (atc = package.atc) ? atc.code : 'Z'
      (atcs[code] ||= Util::AnnotatedList.new(:atc => atc)).push(package)
    end
    count = 0
    limit = @session.lookandfeel.list_limit
    atcs.sort.each { |code, array|
      if(count > limit)
        @model.next_page!
        count = 0
      end
      @model.push(array)
      count += array.size
    }
    @model.page = 0
  end
  def _search(query, dstype)
    if(@model.query == query && @model.dstype == dstype)
      paginate
      sort
    else
      super
    end
  end
  def _sort_by(model, reverse, &sorter)
    model.collect! { |array|
      super(array, reverse, &sorter)
    }
  end
end
      end
    end
  end
end
