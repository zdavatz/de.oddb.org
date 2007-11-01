#!/usr/bin/ruby

################################################################################
# Class   : rtf_tools/reader
#
# Version : 1.000
# Dated   : 25th January 2003
# Author  : Peter Hickman <peterhi@ntlworld.com>
#
# Description
# -----------
# Take a string of RTF as input and return it token by token.
################################################################################

class RTFReader
	TOKEN_CONTROL = 'control'
	TOKEN_EOF = 'eof'
	TOKEN_GROUP = 'group'
	TOKEN_TEXT = 'text'

	def initialize(buffer)
		@bufferstring = buffer
		@buffer = Array.new
	end

	public

	def get_token
		@token = ''
		@body = ''
		@extra = ''

		chr = _read_char

		if not chr then
			@token = TOKEN_EOF
		else
			@body << chr

			case chr
			when '{', '}'
				@token = TOKEN_GROUP
			when '\\'
				chr = _read_char

				@body << chr

				if chr =~ /[a-zA-Z]/ then
					@token = TOKEN_CONTROL
					process_control
				else
					@token = TOKEN_TEXT
					process_text
				end
			else
				@token = TOKEN_TEXT
				process_text
			end
		end

		if @token == TOKEN_CONTROL and @body =~ /^(\\[a-zA-Z]+)(.*)$/ then
			@body = $1
			@extra = $2
		end

		return @token, @body, @extra
	end

	private

	def _read_char
		if @buffer.empty? then
			if @bufferstring.size > 100 then
				x = @bufferstring.slice!(0,100)
			else
				x = @bufferstring
				@bufferstring = ''
			end

			@buffer = x.split(//)
		end

		return @buffer.shift
	end

	def _unread_char(char)
		@buffer.unshift(char)
	end

	def process_text
		chr = _read_char
		while chr and chr != '\\' and chr != '{' and chr != '}' do
			@body << chr
			chr = _read_char
		end
		_unread_char(chr) if chr
	end

	def process_control
		chr = _read_char

		while chr =~ /[a-zA-Z]/ do
			@body << chr
			chr = _read_char
		end

		if chr == '-' then
			@body << chr
			chr = _read_char
		end

		while chr =~ /[0-9]/ do
			@body << chr
			chr = _read_char
		end

		if chr == ' ' then
			@body << chr
			chr = _read_char
		end

		_unread_char(chr)
	end
end

if $0 == __FILE__ then
	line = '{\pard \qc \b\f3\fs40 Section 1: The Larch \par}'

	r = RTFReader.new(line)

	puts line

	type, value, extra = r.get_token
	while type != 'eof' do
		puts "[#{type},#{value},#{extra}]\n"

		type, value, extra = r.get_token
	end
end
