#!/usr/bin/env ruby
# Import::Rtf -- de.oddb.org -- 16.10.2007 -- hwyss@ywesee.com

require 'fileutils'
require 'iconv'
require 'oddb/redist/rtf_tools/reader'
require 'oddb/text/chapter'
require 'oddb/text/document'
require 'oddb/text/paragraph'
require 'oddb/text/picture'
require 'oddb/text/table'
require 'RMagick'

module ODDB
  module Import
class RtfReader < RTFReader
	def _read_char
		if @buffer.empty? && (x = @bufferstring.read(100))
			@buffer = x.split(//)
		end
		@buffer.shift
	end
end
class Rtf
  SYMBOLS = { 
    0101 => "Α",
    0102 => "Β",
    0103 => "Χ",
    0104 => "Δ",
    0105 => "Ε",
    0110 => "Η",
    0240 => "€",
    0107 => "Γ",
    0301 => "ℑ",
    0111 => "Ι",
    0113 => "Κ",
    0114 => "Λ",
    0115 => "Μ",
    0116 => "Ν",
    0127 => "Ω",
    0117 => "Ο",
    0106 => "Φ",
    0120 => "Π",
    0131 => "Ψ",
    0302 => "ℜ",
    0122 => "Ρ",
    0123 => "Σ",
    0124 => "Τ",
    0121 => "Θ",
    0125 => "Υ",
    0241 => "ϒ",
    0130 => "Ξ",
    0132 => "Ζ",
    0300 => "ℵ",
    0141 => "α",
    0046 => "&",
    0320 => "∠",
    0341 => "〈",
    0361 => "〉",
    0273 => "≈",
    0253 => "↔",
    0333 => "⇔",
    0337 => "⇓",
    0334 => "⇐",
    0336 => "⇒",
    0335 => "⇑",
    0257 => "↓",
    0276 => "",
    0254 => "←",
    0256 => "→",
    0255 => "↑",
    0275 => "",
    0052 => "∗",
    0174 => "|",
    0142 => "β",
    0173 => "{",
    0175 => "}",
    0354 => "",
    0355 => "",
    0356 => "",
    0374 => "",
    0375 => "",
    0376 => "",
    0357 => "",
    0133 => "[",
    0135 => "]",
    0351 => "",
    0352 => "",
    0353 => "",
    0371 => "",
    0372 => "",
    0373 => "",
    0267 => "•",
    0277 => "↵",
    0143 => "χ",
    0304 => "⊗",
    0305 => "⊕",
    0247 => "♣",
    0072 => ":",
    0054 => ",",
    0100 => "≅",
    0343 => "",
    0260 => "°",
    0144 => "δ",
    0250 => "♦",
    0270 => "÷",
    0327 => "⋅",
    0070 => "8",
    0316 => "∈",
    0274 => "…",
    0306 => "∅",
    0145 => "ε",
    0075 => "=",
    0272 => "≡",
    0150 => "η",
    0041 => "!",
    0044 => "∃",
    0065 => "5",
    0246 => "ƒ",
    0064 => "4",
    0244 => "⁄",
    0147 => "γ",
    0321 => "∇",
    0076 => ">",
    0263 => "≥",
    0251 => "♥",
    0245 => "∞",
    0362 => "∫",
    0363 => "⌠",
    0364 => "",
    0365 => "⌡",
    0307 => "∩",
    0151 => "ι",
    0153 => "κ",
    0154 => "λ",
    0074 => "<",
    0243 => "≤",
    0331 => "∧",
    0330 => "¬",
    0332 => "∨",
    0340 => "◊",
    0055 => "−",
    0242 => "′",
    0155 => "μ",
    0264 => "×",
    0071 => "9",
    0317 => "∉",
    0271 => "≠",
    0313 => "⊄",
    0156 => "ν",
    0043 => "#",
    0167 => "ω",
    0166 => "ϖ",
    0157 => "ο",
    0061 => "1",
    0050 => "(",
    0051 => ")",
    0346 => "",
    0347 => "",
    0350 => "",
    0366 => "",
    0367 => "",
    0370 => "",
    0266 => "∂",
    0045 => "%",
    0056 => ".",
    0136 => "⊥",
    0146 => "φ",
    0160 => "π",
    0053 => "+",
    0261 => "±",
    0325 => "Π",
    0314 => "⊂",
    0311 => "⊃",
    0265 => "∝",
    0171 => "ψ",
    0077 => "?",
    0326 => "√",
    0315 => "⊆",
    0312 => "⊇",
    0342 => "",
    0162 => "ρ",
    0262 => "″",
    0073 => ";",
    0067 => "7",
    0163 => "σ",
    0126 => "ς",
    0176 => "∼",
    0066 => "6",
    0057 => "/",
    0252 => "♠",
    0047 => "∋",
    0345 => "Σ",
    0164 => "τ",
    0134 => "∴",
    0161 => "θ",
    0063 => "3",
    0344 => "",
    0062 => "2",
    0137 => "_",
    0310 => "∪",
    0042 => "∀",
    0165 => "υ",
    0303 => "℘",
    0170 => "ξ",
    0060 => "0",
    0172 => "ζ",
  }
  def import(io)
    reader = RtfReader.new(io)
    @iconv = Iconv.new('utf8//IGNORE//TRANSLIT', "cp1252")
    @groups = [[]]
    init
    begin
      type = import_token(reader)
    end until type == 'eof'
    @document
  end
  def current_chapter
    @document.chapters.last
  end
  def current_group
    @groups.last
  end
  def current_table
    @table ||= Text::Table.new
  end
  def identify_chapter buffer
    current_chapter
  end
  def ignore?
    !(current_group & [:ignore, 'v']).empty?
  end
  def import_control(value, extra)
    case value
    when '\\ansicpg'
      @iconv = Iconv.new('utf8//IGNORE//TRANSLIT', "cp#{extra}")
    when '\\fonttbl', '\\colortbl', '\\stylesheet', '\\listtable', 
         '\\listoverridetable', '\\rsidtbl', '\\generator', '\\info',
         '\header', '\\headerr', '\footer', '\\footerf', '\\footerr',
         '\\deleted'
      current_group.push :ignore
    when '\\b', '\\i', '\\sub', '\\super', '\\v'
      if(extra == '0')
        current_group.delete(value[1..-1])
      else
        current_group.push(value[1..-1]).uniq!
      end
    when '\\cell'
      current_table << @buffer
      @buffer = next_paragraph
      @table.next_cell!
    when '\\dn'
      current_group.push "sub"
    when '\\endash', '\\emdash' 
      @buffer << '-'
    when '\\fs'
      set_font_size(extra)
    when '\\intbl'
      @table_flag = true
    when '\\line'
      @buffer << "\n" unless @buffer.empty?
    when '\\par'
      if @table_flag
        # do nothing
      elsif @table
        @table.clean!
        unless @table.empty?
          current_chapter.add_paragraph @table
        end
        @table = nil
      else
        unless ignore? || @buffer.empty?
          chapter = identify_chapter @buffer
          chapter.add_paragraph @buffer
          @buffer = next_paragraph
        end
      end
    when '\\pict'
      current_group.push :picture
      @buffer = Text::Picture.new
    when '\\pich'
      @buffer.height = extra.to_i
    when '\\picw'
      @buffer.width = extra.to_i
    when '\\picscalex'
      @buffer.xscale = extra.to_i
    when '\\picscaley'
      @buffer.yscale = extra.to_i
    when '\\plain'
      current_group.delete_if { |item| item.is_a? String }
    when '\\row'
      current_table.next_row!
      @table_flag = nil
    when '\\tab'
      _import_text("\t")
    when '\\up'
      current_group.push "super"
    when '\\wmetafile'
      current_group.push "wmf"
    end
  end
  def import_group(value, extra)
    case value
    when '{'
      @groups.push current_group.dup
    when '}'
      @groups.pop
      if(@buffer.is_a?(Text::Picture) && !current_group.include?(:picture))
        @buffer = next_paragraph
      end
    end
  end
  def import_text(value, extra)
    case value
    when '\\*'
      current_group.push :ignore
    when /SYMBOL\s*\d/i
      _import_text SYMBOLS[value[/\d+/].to_i].to_s
    else
      value.gsub!(/\r\n/, '')
      value.gsub!(/\\'([0-9a-f]{2})/i) { |match|
        match[2,2].to_i(16).chr
      }
      begin 
        value = @iconv.iconv(value)
      rescue 
      end
      _import_text(value) unless ignore?
    end
  end
  def _import_text(value)
    @buffer.set_format(*current_group)
    _sanitize_text(value)
    value.gsub!(/\\-/, '')
    value.gsub!(/\\~/, ' ')
    value.gsub!(/\\_/, '-')
    @buffer << value
  end
  def import_token(reader)
    type, value, extra = reader.get_token
    case type
    when 'control'
      if(value == '\\rtf')
        @valid = true
      end
      import_control(value, extra)
    when 'group'
      import_group(value, extra)
    when 'text'
      unless @valid
        raise ArgumentError, "Invalid RTF-File: Text before rtf-version" 
      end
      import_text(value, extra)
    end
    type
  end
  def init
    @buffer = next_paragraph
    @document = Text::Document.new
    @document.add_chapter Text::Chapter.new('default')
  end
  def next_paragraph
    case @buffer
    when Text::Picture
      unless ignore? || @buffer.empty?
        @buffer.finalize!
        path = File.join(ODDB.config.var, @buffer.path)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w') { |fh|
          fh.puts @buffer.to_png
        }
        current_chapter.add_paragraph @buffer
      end
    end
    Text::Paragraph.new
  end
  def parent_group
    @groups[-2] || []
  end
  def set_font_size(size)
  end
  def _sanitize_text(value)
  end
end
  end
end
