module StringTools
  module HTML
    # Сервис безопасного обрезания текста, сожержащего html-разметку
    # В отличии от https://github.com/hgmnz/truncate_html, может удалять и ненужные теги, если они становятся пусты,
    # дополнительно удаляет изображения, если из-за них выходим за лимит
    class Truncate
      SERIALIZE_OPTIONS = {
        indent: 0,
        # сериализуем в xhtml, поскольку при сериализации в html, libxml2 делает чуть больше, чем хотелось бы:
        # http://stackoverflow.com/questions/24174032/prevent-nokogiri-from-url-encoding-src-attributes
        save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML
      }.freeze

      CLEAN_EMPTY_TAGS = %w(p).freeze

      # Public:
      # html - String, исходная разметка
      # options:
      #   limit - Integer, лимит, по которому обрезаем текcт
      #   clean_empty_tags - Array of String, список тагов, которые можно удалять, если становятся пустыми
      #   sericalize_options - Hash, опции сериализации
      def initialize(html, limit:, clean_empty_tags: CLEAN_EMPTY_TAGS, serialize_options: SERIALIZE_OPTIONS)
        @fragment = Nokogiri::HTML::DocumentFragment.parse(html)
        @limit = limit
        @clean_empty_tags = clean_empty_tags || []
        @serialize_options = serialize_options.dup
        @current = nil
      end

      # Public: Производим преобразвования
      #
      # Returns String.
      def call
        self.count = serialize.length - limit
        self.current = find_starting_node

        truncate! while count > 0 && current

        if count > 0
          ''
        else
          serialize
        end
      end

      private

      attr_reader :fragment, :limit, :clean_empty_tags, :serialize_options
      attr_accessor :count, :current

      def find_starting_node
        fragment.xpath('.//text()|img'.freeze).last
      end

      def find_previous_sibling(node)
        while node
          node = node.previous_sibling
          return node if truncate_class(node)
        end
      end

      def truncate!
        case truncate_class
        when :text
          truncate_text!
        when :img
          truncate_img!
        else
          raise 'unreachable'
        end
      end

      def truncate_text!
        if current.content.length <= count
          unlink!
        else
          current.content = current.content[0...-count]
          self.count = 0
        end
      end

      def truncate_img!
        unlink!
      end

      def unlink!
        parent = current.parent
        if parent && clean_empty_tags.include?(parent.name) && parent.children.count == 1
          self.count -= parent.to_xhtml.length
          parent.unlink
        else
          self.count -= current.to_xhtml.length
          next_candidate = find_previous_sibling(current)
          current.unlink
        end

        self.current = next_candidate || find_starting_node
      end

      def truncate_class(node = current)
        return :text if node.is_a?(Nokogiri::XML::Text)
        return :img if node.is_a?(Nokogiri::XML::Element) && node.name == 'img'.freeze
        nil
      end


      def serialize
        fragment.children.map { |node| node.serialize serialize_options }.join
      end
    end
  end
end
