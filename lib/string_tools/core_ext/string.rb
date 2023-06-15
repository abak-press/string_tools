# frozen_string_literal: true
require 'rchardet19'
require 'addressable/uri'
require 'active_support/core_ext/module'
require 'active_support/version'
require 'action_pack'
require 'string_tools/string'

class String
  %w[auto_link excerpt highlight sanitize simple_format word_wrap].each do |method|
    eval <<-EVAL
      def #{method}(*args)
        ActionController::Base.helpers.#{method}(self, *args)
      end
    EVAL

  end

  # возвращает строку из которой удалены HTML-теги
  # символы <>&"  остаются без изменения
  def strip_tags
    Nokogiri::HTML5.parse(self).content
  end

  # '11,3'.to_f
  # => 11.3
  def to_f_with_strip_comma
    self.gsub(/,/,'.').to_f_without_strip_comma
  end
  alias_method_chain :to_f, :strip_comma

  def to_b
    StringTools::String.new(self).to_b
  end

  def to_script_safe_json
    self.to_json.gsub('</script>', '</" + "script>" + "')
  end

  def naturalized
    scan(/[^\d\.]+|[\d\.]+/).map{|f| f.match(/^\d+(\.\d+)?$/) ? f.to_f : f }
  end

  def self.natcmp(str1, str2)
    str1, str2 = str1.dup, str2.dup
    compare_expression = /^(\D*)((?:\d+(?:\.\d+)?)*)(.*)$/

    # Remove all whitespace
    str1.gsub!(/\s*/, '')
    str2.gsub!(/\s*/, '')

    while (str1.length > 0) or (str2.length > 0)
      # Extract non-digits, digits and rest of string
      str1 =~ compare_expression
      chars1, num1, str1 = $1.dup, $2.dup, $3.dup

      str2 =~ compare_expression
      chars2, num2, str2 = $1.dup, $2.dup, $3.dup

      # Compare the non-digits
      case (chars1 <=> chars2)
      when 0 # Non-digits are the same, compare the digits...
        # If either number begins with a zero, then compare alphabetically,
        # otherwise compare numerically
        if !(num1[0] == 48 && num1[1] != 46) and !(num2[0] == 48 && num2[1] != 46)
          num1, num2 = num1.to_f, num2.to_f
        end

        case (num1 <=> num2)
        when -1 then return -1
        when 1 then return 1
        end
      when -1 then return -1
      when 1 then return 1
      end # case

    end # while

    # Strings are naturally equal
    0
  end

  # Выполняет преобразование строки в punycode.
  def to_punycode
    Addressable::URI.parse(self).normalize.to_s
  end

  # Embed in a String to clear all previous ANSI sequences.
  ANSI_CLEAR     = "\e[0m"
  ANSI_BOLD      = "\e[1m"
  ANSI_UNDERLINE = "\e[4m"

  # Colors
  BLACK     = "\e[30m"
  RED       = "\e[31m"
  GREEN     = "\e[32m"
  YELLOW    = "\e[33m"
  BLUE      = "\e[34m"
  MAGENTA   = "\e[35m"
  CYAN      = "\e[36m"
  WHITE     = "\e[37m"

  # === Synopsys
  #   Colorize string (for terminals)
  #   Does not work with sprintf yet
  #
  # === Usage
  #   "ln -s".colorize(:red)
  #
  # === Args
  #   +color+ - symbol, one of the following (black, white, red, green, yellow, blue, magenta, cyan)
  #   +bold_or_options+ - True/False or Hash
  def colorize(color, bold_or_options = nil)
    is_bold      = bold_or_options.is_a?(TrueClass)
    is_underline = false

    if bold_or_options.is_a?(Hash)
      is_bold    ||= bold_or_options[:bold]
      is_underline = bold_or_options[:underline]
    end

    raise ArgumentError('Color must be a symbol') unless color.is_a?(Symbol)
    color_const = color.to_s.upcase.to_sym

    raise ArgumentError('Unknown color') unless self.class.const_defined?(color_const)
    ascii_color = self.class.const_get(color_const)

    s = surround_with_ansi(ascii_color)
    s = s.bold      if is_bold
    s = s.underline if is_underline
    s
  end

  # === Synopsys
  #   Make text bolder (for ASCII terminals)
  def bold
    surround_with_ansi(ANSI_BOLD)
  end

  # === Synopsys
  #   Make text underlined (for ASCII terminals)
  def underline
    surround_with_ansi(ANSI_UNDERLINE)
  end

  # === Synopsys
  #   remove colors from colorized string
  def remove_colors
    gsub(/\e\[\d+m/, '')
  end

  [:black, :white, :red, :green, :yellow, :blue, :magenta, :cyan].each do |color|
    define_method color do |*args|
      colorize(color, *args)
    end
  end

  WIN_1251_ENCODING = 'windows-1251'
  # shorthand
  def detect_encoding
    e = ::CharDet.detect(self)["encoding"]
    e = WIN_1251_ENCODING if StringTools::CharDet::CP1251_COMPATIBLE_ENCODINGS.include?(e)
    e
  end

  def to_utf8(inplace = false)
    return self if valid_encoding? && is_utf8?

    source_enc = detect_encoding
    return '' unless source_enc

    encode_utf8(source_enc, inplace)
  end

  def to_utf8!
    to_utf8(true)
  end

  def to_cp1251
    encode 'cp1251', undef: :replace, invalid: :replace, replace: ''
  end

  def to_cp1251!
    self.replace(self.to_cp1251)
  end

  def mb_downcase
    # https://github.com/rails/rails/commit/393e19e508a08ede0f5037bccb984e3eb252d579
    if ActiveSupport::VERSION::STRING >= '4.0.0' && ActiveSupport::VERSION::STRING <= '4.2.0'
      ActiveSupport::Multibyte::Unicode.send(:database).codepoints
    end

    mb_chars.downcase.to_s
  end

  # Public: returns copy of string with all non-printable characters removed
  #
  # Examples
  #
  #   "q\uFFFEw\uFFFFe\uFFF0r\uFDD0t\uFDEFy".remove_nonprintable
  #   # => "qwerty"
  #
  # Returns String
  def remove_nonprintable
    gsub(/[^[:print:]\n\t]/i, '')
  end

  # Public: removes all non-printable characters from string
  #
  # Examples
  #
  #   "q\uFFFEw\uFFFFe\uFFF0r\uFDD0t\uFDEFy".remove_nonprintable!
  #   # => "qwerty"
  #
  # Returns String
  def remove_nonprintable!
    replace(remove_nonprintable)
  end

  private

  def encode_utf8(source_enc, inplace = false)
    args = ['utf-8', source_enc, undef: :replace, invalid: :replace, replace: '']

    inplace ? encode!(*args) : encode(*args)
  end

  def surround_with_ansi(ascii_seq)
    "#{ascii_seq}#{protect_escape_of(ascii_seq)}#{ANSI_CLEAR}"
  end

  def protect_escape_of(ascii_seq)
    gsub(Regexp.new(Regexp.escape(ANSI_CLEAR)), "#{ANSI_CLEAR}#{ascii_seq}")
  end
end
