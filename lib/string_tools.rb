# coding: utf-8
require 'string_tools/version'
require 'ru_propisju'
require 'sanitize'
require 'active_support/core_ext/string'
require 'string_tools/core_ext/string'

module StringTools
  autoload :HTML, 'string_tools/html'

  module CharDet
    CP1251_COMPATIBLE_ENCODINGS =
      %w(windows-1253 windows-1254 windows-1255 windows-1256 windows-1258 EUC-TW ISO-8859-8).freeze

    # Возвращает true если строка содержит допустимую
    # последовательность байтов для кодировки utf8 и false в обратном случае
    # см. http://en.wikipedia.org/wiki/UTF-8
    def valid_utf8?(string)
      string.respond_to?(:is_utf8?) && string.is_utf8?
    end

    # shorthand
    def detect_encoding(str)
      str.detect_encoding
    end

    # привести строку к utf8
    def to_utf8(str)
      str.to_utf8
    end

    def to_cp1251(str)
      str.to_cp1251
    end
  end
  extend CharDet

  module WordProcessing
    def truncate_words(text, length = 75)
      return if text.nil?

      if text.mb_chars.size > length
        new_length = text.mb_chars[0...length].rindex(/[^[:word:]]/)
        text.mb_chars[0...new_length.to_i]
      else
        text
      end
    rescue
      text[0...length]
    end
  end
  extend WordProcessing

  module ActionControllerExtension
    def accepts_non_utf8_params(*args)
      args.each do |arg|
        next unless arg.is_a?(Symbol) || arg.is_a?(::String)
        arg = arg.to_sym

        class_eval do
          before_filter { |controller|
            decode = lambda { |s|
              if s.is_a?(Hash)
                s.to_a.map { |k, v| [k, StringTools.to_utf8(v)]}.to_hash
              elsif s.is_a?(Array)
                s.map { |v| StringTools.to_utf8(v) }
              else
                StringTools.to_utf8(s)
              end
            }

            controller.params[arg] = decode.call(controller.params[arg]) unless controller.params[arg].nil?
          }
        end
      end
    end

    alias_method :accepts_non_utf8_param, :accepts_non_utf8_params
  end

  module Sanitizing
    def sanitize(text, options = {})
      sanitizer = options.delete(:sanitizer)
      sanitizer = StringTools::Sanitizer::Base.new unless sanitizer.respond_to?(:sanitize)
      sanitizer.sanitize(text, options)
    end

    # Public: вычищает ASCII Control Characters из строки
    #
    # string - String строка, из которой удаляем символы
    #
    # Returns String
    def clear_control_characters(string)
      string.tr("\u0000-\u001f", '')
    end

    # Public: вычищает Unicode символы-разделители из строки
    #
    # string - String строка, из которой удаляем символы
    #
    # Returns String
    def clear_unicode_separator_characters(string)
      string.tr("\u2028-\u2029", '')
    end

    # Public: вычищает все html тэги и пробельные символы
    #
    # string - String строка для очистки
    #
    # Examples
    #
    #   strip_all_tags_and_entities("<a>ссылка с&nbsp;пробелом</a><p>параграф&#9;с\tтабуляцией</p>")
    #   # => "ссылкаспробелом параграфстабуляцией "
    #
    # Returns String
    def strip_all_tags_and_entities(string)
      Sanitize.fragment(string.gsub(/&#([0-9]|10|11|12|13);|&nbsp;|\xc2\xa0|\s/, ''))
    end

    # Public: вычищает html тэги кроме переносов
    #
    # string - String строка для очистки
    #
    # Examples
    #
    #   strip_tags_leave_br("<a></a><ul><li>элемент списка</li></ul><p>параграф</p>просто перенос<br>")
    #   # => "<br />элемент списка<br /><br />параграф<br />просто перенос<br>"
    #
    # Returns String
    def strip_tags_leave_br(string)
      sanitized = Sanitize.fragment(string, remove_contents: %w(style script), elements: %w(p ul li br blockquote))

      sanitized.gsub!(/<(p|li|blockquote)[^>]*>/, '')
      sanitized.gsub!(%r{<(br /|ul[^>]*|/[^>]*)>}, '<br />')
      sanitized.gsub!(/<br \/>(\s|\302\240)+/, '<br />')

      sanitized
    end
  end
  extend Sanitizing

  module Sanitizer
    class Base
      TAGS_WITH_ATTRIBUTES = {
        'p'     => %w(align style),
        'div'   => %w(align style),
        'span'  => %w(align style),
        'td'    => %w(align width valign colspan rowspan style),
        'th'    => %w(align width valign colspan rowspan style),
        'a'     => %w(href target name style),
        'table' => %w(cellpadding cellspacing width border align style),
        'img'   => %w(src width height style)
      }.freeze

      TAGS_WITHOUT_ATTRIBUTES = %w(b strong i em sup sub ul ol li blockquote br tr u caption thead s).freeze

      def sanitize(str, attrs = {})
        # для корректного обрезания utf строчек режем через mb_chars
        # для защиты от перегрузки парсера пропускаем максимум 1 мегабайт текста
        # длина русского символа в utf-8 - 2 байта, 1Мб/2б = 524288 = 2**19 символов
        # длина по символам с перестраховкой, т.к. латинские символы(теги, например) занимают 1 байт
        str = str.mb_chars.slice(0..(2**19)).to_s

        # Мерджим добавочные теги и атрибуты
        attributes = TAGS_WITH_ATTRIBUTES.merge(attrs)
        elements = attributes.keys | TAGS_WITHOUT_ATTRIBUTES

        transformers = [LINK_NORMALIZER]
        transformers << IframeNormalizer.new(attributes['iframe']) if attributes.key?('iframe')

        Sanitize.fragment(
          str,
          :attributes => attributes,
          :elements => elements,
          :css => {:properties => Sanitize::Config::RELAXED[:css][:properties]},
          :remove_contents => %w(style script),
          :allow_comments => false,
          :transformers => transformers
        )
      end
    end

    # приводит ссылки согласно стандарту, не корёжит
    # http://www.фермаежей.рф => http://www.xn--80ajbaetq5a8a.xn--p1ai
    class LinkNormalizer
      def call(env)
        node = env[:node]
        case node.name
        when 'a'.freeze
          normalize_link node, 'href'.freeze
        when 'img'.freeze
          normalize_link node, 'src'.freeze
        end
      end

      private

      def normalize_link(node, attr_name)
        return unless node[attr_name]
        node[attr_name] = Addressable::URI.parse(node[attr_name]).normalize.to_s
      rescue Addressable::URI::InvalidURIError
        node.swap node.children
      end
    end

    class IframeNormalizer
      def initialize(attributes)
        @attributes = attributes
      end

      def call(env)
        node = env[:node]

        return unless node.name == 'iframe'

        unless node[:src] =~ %r{^(http|https):?\/\/(www\.)?youtube?\.com\/}
          node.unlink
          return
        end

        Sanitize.node!(env[:node], elements: %w(iframe), attributes: {'iframe' => @attributes})
      end
    end

    LINK_NORMALIZER = LinkNormalizer.new
  end

  module SumInWords
    # Сумма в рублях прописью. Кол-во копеек выводится всегда. Первая буква заглавная
    def rublej_propisju(amount)
      kop = (amount.divmod(1)[1]*100).round
      result = RuPropisju.rublej(amount.to_i).capitalize
      result << " %.2d " % kop
      result << RuPropisju.choose_plural(kop, 'копейка', 'копейки', 'копеек')
    end
  end
  extend SumInWords

  module Uri
    def add_params_to_url(url, params = nil, options = {normalize: true})
      uri = Addressable::URI.parse(url)
      uri = Addressable::URI.parse("http://#{url}") unless uri.scheme
      uri.query_values = (uri.query_values || {}).merge!(params.stringify_keys) if params.present?

      uri.normalize! if options[:normalize]

      uri.to_s
    rescue Addressable::URI::InvalidURIError
      nil
    end
  end
  extend Uri

  module Transliteration
    LAYOUT_EN_TO_RU_MAP = {
      'q' => 'й', 'Q' => 'Й',
      'w' => 'ц', 'W' => 'Ц',
      'e' => 'у', 'E' => 'У',
      'r' => 'к', 'R' => 'К',
      't' => 'е', 'T' => 'Е',
      'y' => 'н', 'Y' => 'Н',
      'u' => 'г', 'U' => 'Г',
      'i' => 'ш', 'I' => 'Ш',
      'o' => 'щ', 'O' => 'Щ',
      'p' => 'з', 'P' => 'З',
      '[' => 'х',
      '{' => 'Х',
      ']' => 'ъ',
      '}' => 'Ъ',
      '|' => '/',
      '`' => 'ё',
      '~' => 'Ё',
      'a' => 'ф', 'A' => 'Ф',
      's' => 'ы', 'S' => 'Ы',
      'd' => 'в', 'D' => 'В',
      'f' => 'а', 'F' => 'А',
      'g' => 'п', 'G' => 'П',
      'h' => 'р', 'H' => 'Р',
      'j' => 'о', 'J' => 'О',
      'k' => 'л', 'K' => 'Л',
      'l' => 'д', 'L' => 'Д',
      ';' => 'ж',
      ':' => 'Ж',
      "'" => 'э',
      '"' => 'Э',
      'z' => 'я', 'Z' => 'Я',
      'x' => 'ч', 'X' => 'Ч',
      'c' => 'с', 'C' => 'С',
      'v' => 'м', 'V' => 'М',
      'b' => 'и', 'B' => 'И',
      'n' => 'т', 'N' => 'Т',
      'm' => 'ь', 'M' => 'Ь',
      ',' => 'б',
      '<' => 'Б',
      '.' => 'ю',
      '>' => 'Ю',
      '/' => '.',
      '?' => ',',
      '@' => '"',
      '#' => '№',
      '$' => ';',
      '^' => ':',
      '&' => '?'
    }.freeze
    LAYOUT_RU_TO_EN_MAP = {
      'й' => 'q', 'Й' => 'Q',
      'ц' => 'w', 'Ц' => 'W',
      'у' => 'e', 'У' => 'E',
      'к' => 'r', 'К' => 'R',
      'е' => 't', 'Е' => 'T',
      'н' => 'y', 'Н' => 'Y',
      'г' => 'u', 'Г' => 'U',
      'ш' => 'i', 'Ш' => 'I',
      'щ' => 'o', 'Щ' => 'O',
      'з' => 'p', 'З' => 'P',
      'х' => '[',
      'Х' => '{',
      'ъ' => ']',
      'Ъ' => '}',
      '/' => '|',
      'ё' => '`',
      'Ё' => '~',
      'ф' => 'a', 'Ф' => 'A',
      'ы' => 's', 'Ы' => 'S',
      'в' => 'd', 'В' => 'D',
      'а' => 'f', 'А' => 'F',
      'п' => 'g', 'П' => 'G',
      'р' => 'h', 'Р' => 'H',
      'о' => 'j', 'О' => 'J',
      'л' => 'k', 'Л' => 'K',
      'д' => 'l', 'Д' => 'L',
      'ж' => ';',
      'Ж' => ':',
      'э' => "'",
      'Э' => '"',
      'я' => 'z', 'Я' => 'Z',
      'ч' => 'x', 'Ч' => 'X',
      'с' => 'c', 'С' => 'C',
      'м' => 'v', 'М' => 'V',
      'и' => 'b', 'И' => 'B',
      'т' => 'n', 'Т' => 'N',
      'ь' => 'm', 'Ь' => 'M',
      'б' => ',',
      'Б' => '<',
      'ю' => '.',
      'Ю' => '>',
      '.' => '/',
      ',' => '?',
      '"' => '@',
      '№' => '#',
      ';' => '$',
      ':' => '^',
      '?' => '&'
    }.freeze
    LAYOUT_PERSISTENT = {
      '0' => '0',
      '1' => '1',
      '2' => '2',
      '3' => '3',
      '4' => '4',
      '5' => '5',
      '6' => '6',
      '7' => '7',
      '8' => '8',
      '9' => '9',
      '!' => '!',
      '*' => '*',
      '(' => '(',
      ')' => ')',
      ' ' => ' ',
      '-' => '-',
      '—' => '—',
      '_' => '_',
      '=' => '=',
      '+' => '+'
    }.freeze
    TRANSLIT_RU_TO_EN_MAP = {
      'щ' => 'shh', 'Щ' => 'Shh',
      'ё' => 'yo', 'Ё' => 'Yo',
      'ж' => 'zh', 'Ж' => 'Zh',
      'ц' => 'cz', 'Ц' => 'Cz',
      'ч' => 'ch', 'Ч' => 'Ch',
      'ш' => 'sh', 'Ш' => 'Sh',
      'ъ' => '``', 'Ъ' => '``',
      'ы' => 'y`', 'Ы' => 'Y`',
      'э' => 'e`', 'Э' => 'E`',
      'ю' => 'yu', 'Ю' => 'Yu',
      'я' => 'ya', 'Я' => 'Ya',
      'а' => 'a', 'А' => 'A',
      'б' => 'b', 'Б' => 'B',
      'в' => 'v', 'В' => 'V',
      'г' => 'g', 'Г' => 'G',
      'д' => 'd', 'Д' => 'D',
      'е' => 'e', 'Е' => 'E',
      'з' => 'z', 'З' => 'Z',
      'и' => 'i', 'И' => 'I',
      'й' => 'j', 'Й' => 'J',
      'к' => 'k', 'К' => 'K',
      'л' => 'l', 'Л' => 'L',
      'м' => 'm', 'М' => 'M',
      'н' => 'n', 'Н' => 'N',
      'о' => 'o', 'О' => 'O',
      'п' => 'p', 'П' => 'P',
      'р' => 'r', 'Р' => 'R',
      'с' => 's', 'С' => 'S',
      'т' => 't', 'Т' => 'T',
      'у' => 'u', 'У' => 'U',
      'ф' => 'f', 'Ф' => 'F',
      'х' => 'x', 'Х' => 'X',
      'ь' => '`', 'Ь' => '`'
    }.freeze

    # Public: варианты строки с учетом смены раскладки и/или транслитерации для Русского и Английского языков
    #   Смена раскладки выполняется в обе стороны, транслитерация - с Русского на Английский.
    #
    # str - String
    #
    # Examples
    #   transliteration_variations('Ruby')
    #     => ['Ruby', 'Кгин', 'kgin']
    #   transliteration_variations('Слово')
    #     => ['Слово', 'ckjdj', 'slovo']
    #   transliteration_variations('КомпанияPro')
    #     => ['КомпанияPro']
    #   transliteration_variations('ويكيبيدي')
    #     => ['ويكيبيدي']
    #
    # returns Array of String
    def transliteration_variations(str)
      str_as_chars = str.chars
      converted = convert_layout(str_as_chars)

      layout_swap = converted[:chars].try(:join)
      tranliterated = (converted[:was_ru] ? transliterate(str_as_chars) : transliterate(converted[:chars])).try(:join)

      [str, layout_swap, tranliterated].tap(&:compact!)
    end

    private

    # Internal: Смена раскладки массива символов, ru <-> en.
    #   Возвращает Hash с двумя ключами:
    #     :chars  - Array, символы в другой раскладке(nil если не удалось сменить раскладку)
    #     :was_ru - Bool, принадлежали ли все символы русскому языку.
    #
    # splitted_string - Array of String
    #
    # Example:
    #  convert_layout(['a', 'b', 'c']) =>
    #    {chars: ['ф', 'и', 'с'], was_ru: false}
    #  convert_layout(['а', 'б', 'в']) =>
    #    {chars: ['f', ',', 'd'], was_ru: true}
    #  convert_layout(['ﻮ', 'ﻴ', 'ﻜ']) =>
    #    {chars: nil, was_ru: false}
    #
    # returns Array
    def convert_layout(splitted_string)
      str_arr = splitted_string.map do |char|
        LAYOUT_RU_TO_EN_MAP[char] || LAYOUT_PERSISTENT[char] || break
      end

      return {chars: str_arr, was_ru: true} if str_arr

      {chars: splitted_string.map { |char| LAYOUT_EN_TO_RU_MAP[char] || LAYOUT_PERSISTENT[char] || break },
       was_ru: false}
    end

    # Internal: Транслитерация массива символов, ru -> en
    #  Если символа нет в словаре, не изменяет его.
    #
    # splitted string - Array of String
    #
    # Returns Array
    def transliterate(splitted_string)
      return unless splitted_string

      splitted_string.map { |char| TRANSLIT_RU_TO_EN_MAP[char] || char }
    end
  end
  extend Transliteration
end
