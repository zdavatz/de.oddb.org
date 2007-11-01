#!/usr/bin/env ruby
# Html::View::Document -- de.oddb.org -- 30.10.2007 -- hwyss@ywesee.com

require 'htmlgrid/divlist'
require 'htmlgrid/image'

module ODDB
  module Html
    module View
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
    super
  end
end
    end
  end
end
