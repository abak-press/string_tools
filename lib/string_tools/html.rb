# coding: utf-8
require 'loofah'
require 'uri'

module StringTools
  module HTML
    # минимальная длина строки, в которой могут быть ссылки
    TEXT_WITH_LINKS_MINIMUM_LENGTH = '<a href="'.length

    # Public: Удаляет ссылки на неразрешенные домены
    #
    # html    - String содержимое потенциально ненужных ссылок
    # options - Hash
    #         :whitelist - Array of String разрешенныe домены
    #
    # Examples
    #   html = '<a href="https://www.yandex.ru">yandex</a>'
    #
    #   StringTools::HTML.remove_links(html, whitelist: ['google.com'])
    #   # => 'yandex'
    #
    #   StringTools::HTML.remove_links(html, whitelist: ['yandex.ru'])
    #   # => '<a href="https://www.yandex.ru">yandex</a>'
    #
    #   StringTools::HTML.remove_links(html, whitelist: ['www.yandex.ru'])
    #   # => '<a href="https://www.yandex.ru">yandex</a>'
    #
    #   html = '<a href="https://yandex.ru">yandex</a>'
    #
    #   StringTools::HTML.remove_links(html, whitelist: ['www.yandex.ru'])
    #   # => 'yandex'
    #
    # Returns String without links to external resources
    def self.remove_links(html, options = {})
      return html if html.length < TEXT_WITH_LINKS_MINIMUM_LENGTH

      Loofah.fragment(html).scrub!(LinksRemoveScrubber.new(options)).to_s
    end

    class LinksRemoveScrubber < Loofah::Scrubber
      def initialize(options)
        @whitelist = options.fetch(:whitelist)
      end

      def scrub(node)
        return unless node.name == 'a'.freeze
        uri = URI.parse(node['href'.freeze])
        node.swap(node.children) unless whitelisted? uri.host
      rescue URI::InvalidURIError => _
        node.swap(node.children)
      end

      def whitelisted?(domain)
        host_parts = domain.split('.'.freeze).reverse!
        host = host_parts[0] # com, ru ...
        1.upto(host_parts.length - 1) do |i|
          subdomain = host_parts[i]
          host = "#{subdomain}.#{host}"
          return true if @whitelist.include? host
        end
        false
      end
    end
  end
end
