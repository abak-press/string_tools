# coding: utf-8
require 'nokogiri'
require 'addressable/uri'
require 'simpleidn'

module StringTools
  module HTML
    # минимальная длина строки, в которой могут быть ссылки
    TEXT_WITH_LINKS_MINIMUM_LENGTH = '<a href="'.length
    HTML_SERIALIZE_OPTIONS = {
      indent: 0,
      # сериализуем в xhtml, поскольку при сериализации в html, libxml2 делает чуть больше, чем хотелось бы:
      # http://stackoverflow.com/questions/24174032/prevent-nokogiri-from-url-encoding-src-attributes
      save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML
    }

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

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      scrubber = LinksRemoveScrubber.new(options)

      doc.css('a'.freeze).each { |node| scrubber.call node }

      if scrubber.done_changes?
        doc.children.map { |node| node.serialize HTML_SERIALIZE_OPTIONS }.join
      else
        html
      end
    end

    class LinksRemoveScrubber
      def initialize(options)
        @whitelist = options.fetch(:whitelist)
        @remove_without_host = options.fetch(:remove_without_host, true)
        @is_have_done_changes = false
      end

      def done_changes?
        @is_have_done_changes
      end

      def call(node)
        href = node['href']
        return if href.blank?
        uri = Addressable::URI.parse(href).normalize
        if !uri.host
          replace_with_content node if @remove_without_host
        elsif !whitelisted?(SimpleIDN.to_unicode(uri.host))
          replace_with_content node
        end
      rescue Addressable::URI::InvalidURIError
        replace_with_content node
      end

      def whitelisted?(domain)
        host_parts = domain.split('.'.freeze)
        host = host_parts[-1] # com, ru ...
        (host_parts.length - 2).downto(0) do |i|
          subdomain = host_parts[i]
          host = "#{subdomain}.#{host}"
          return true if @whitelist.include? host
        end
        false
      end

      private

      def replace_with_content(node)
        node.swap(node.children)
        @is_have_done_changes = true
      end
    end
  end
end
