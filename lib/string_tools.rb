# coding: utf-8
require 'string_tools/version'
require 'ru_propisju'
require 'sanitize'
require 'active_support/core_ext/string'
require 'string_tools/core_ext/string'

module StringTools
  autoload :HTML, 'string_tools/html'

  module CharDet
    # Возвращает true если строка содержит допустимую
    # последовательность байтов для кодировки utf8 и false в обратном случае
    # см. http://en.wikipedia.org/wiki/UTF-8
    def valid_utf8? string
      case string
      when String then string.is_utf8?
      else false
      end
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

    def cp1251_compatible_encodings
      [
        'windows-1253',
        'windows-1254',
        'windows-1255',
        'windows-1256',
        'windows-1258',
        'EUC-TW',
        'ISO-8859-8'
      ]
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
        next unless arg.is_a?(Symbol) || arg.is_a?(String)
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
      sanitized = Sanitize.fragment(string, remove_contents: %w(style javascript), elements: %w(p ul li br blockquote))

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
      }

      TAGS_WITHOUT_ATTRIBUTES = %w(b strong i em sup sub ul ol li blockquote br tr u caption thead)

      def sanitize(str, attr = {})
        # для корректного обрезания utf строчек режем через mb_chars
        # для защиты от перегрузки парсера пропускаем максимум 1 мегабайт текста
        # длина русского символа в utf-8 - 2 байта, 1Мб/2б = 524288 = 2**19 символов
        # длина по символам с перестраховкой, т.к. латинские символы(теги, например) занимают 1 байт
        str = str.mb_chars.slice(0..(2**19)).to_s

        attributes = TAGS_WITH_ATTRIBUTES

        # Мерджим добавочные теги и атрибуты
        attributes.merge!(attr)
        elements = attributes.keys | TAGS_WITHOUT_ATTRIBUTES

        Sanitize.fragment(
          str,
          :attributes => attributes,
          :elements => elements,
          :css => {:properties => Sanitize::Config::RELAXED[:css][:properties]},
          :remove_contents => %w(style javascript),
          :allow_comments => false,
          :transformers => [LINK_NORMALIZER]
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
    def add_params_to_url(url, params = nil)
      uri = Addressable::URI.parse(url)
      uri = Addressable::URI.parse("http://#{url}") unless uri.scheme
      uri.query_values = (uri.query_values || {}).merge!(params.stringify_keys) if params.present?
      uri.normalize.to_s
    end
  end
  extend Uri
end
