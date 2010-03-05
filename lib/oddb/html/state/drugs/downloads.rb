require 'oddb/html/state/global_predefine'
require 'oddb/html/view/drugs/downloads'

module ODDB
  module Html
    module State
      module Drugs
class Downloads < Drugs::Global
  class FileInfo
    attr_reader :name
    def initialize name
      @name = name
    end
    def price times=1
      ODDB.config.prices["org.oddb.de.download.#{times}"][name]
    end
    def file_path
      File.join ODDB.config.export_dir, @name
    end
    def size
      File.size file_path + '.gz'
    end
  end
  DIRECT_EVENT = :downloads
  VIEW = View::Drugs::Downloads
  def init
    prices = ODDB.config.prices['org.oddb.de.download.1']
    @model = Dir.entries(ODDB.config.export_dir).select do |name|
      prices[name] end.collect do |name| FileInfo.new name end
    super
  end
  def downloads
    self
  end
end
      end
    end
  end
end
