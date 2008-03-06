#!/usr/bin/env ruby
# Html::View::Document -- de.oddb.org -- 30.10.2007 -- hwyss@ywesee.com

require 'htmlgrid/divlist'
require 'htmlgrid/image'

module ODDB
  module Html
    module View
class ChapterNames < HtmlGrid::DivList
  COMPONENTS = {
    [0,0] => :link,
  }
  def initialize(type, *args)
    @document_type = type
    super(*args)
  end
  def init
    @current = @session.user_input(:chapter)
    @model = @model.chapter_names.unshift(nil)
    super
    @css_grid = @model.collect { |name| 
      { "id" => "chapter_%s" % name || @document_type } 
    }
  end
  def link(model)
    link = HtmlGrid::Link.new("chapter_#{model || @document_type}", 
                              model, @session, self)
    if(@current != model)
      event, args = @session.direct_event
      args.push :chapter, model if(model)
      link.href = @lookandfeel._event_url(event, args)
    end
    link.value ||= model
    link
  end
end
class Chapter < HtmlGrid::Component
  def to_html(context)
    @model.paragraphs.inject('') { |memo, paragraph|
      memo << case paragraph
              when Text::Picture
                context.img(:src => paragraph.path, :alt => paragraph.filename)
              when Text::Table
                formatted_table(context, paragraph)
              else
                formatted_paragraph(context, paragraph)
              end
    }
  end
  def formatted_paragraph(context, paragraph)
    return '' unless paragraph
    context.p {
      _formatted_paragraph(context, paragraph)
    }
  end
  def _formatted_paragraph(context, paragraph)
    return '' unless paragraph
    paragraph.formats.inject('') { |memo, format|
      memo << formatted_string(context, format.values) { 
        paragraph[format.range].gsub(/\n/, context.br)
      }
    }
  end
  def formatted_string(context, stack, &block)
    if(stack.empty?)
      block.call
    else
      stack = stack.dup
      context.send(stack.pop) { formatted_string(context, stack, &block) }
    end
  end
  def formatted_table(context, table)
    context.table {
      memo = ''
      table.each_normalized { |row|
        memo << context.tr {
          row.inject('') { |tr, cell| 
            tr << context.td { _formatted_paragraph(context, cell) }
          }
        }
      }
      memo
    }
  end
end
class Document < HtmlGrid::DivList
  COMPONENTS = {
    [0,0] => Chapter,
  }
  CSS_MAP = ["chapter"]
  def init
    @model = @model.chapters
    if(name = @session.user_input(:chapter))
      @model = @model.select { |chapter| chapter.name == name }
    end
    super
  end
end
    end
  end
end
