require 'rchardet19'
require 'addressable/uri'
require 'active_support/core_ext/module'
require 'active_record'
require 'action_pack'

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
    ActionController::Base.helpers.strip_tags(self).to_str
  end

  # '11,3'.to_f
  # => 11.3
  def to_f_with_strip_comma
    self.gsub(/,/,'.').to_f_without_strip_comma
  end
  alias_method_chain :to_f, :strip_comma

  def to_b
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean(self) || false
  end

  def to_script_safe_json
    self.to_json.gsub('</script>', '</" + "script>" + "')
  end

  def naturalized
    scan(/[^\d\.]+|[\d\.]+/).map{|f| f.match(/^\d+(\.\d+)?$/) ? f.to_f : f }
  end


  # Выполняет преобразование строки в punycode.
  def to_punycode
    Addressable::URI.parse(self).normalize.to_s
  end


  # shorthand
  def detect_encoding
    e = ::CharDet.detect(self)["encoding"]
    e = 'windows-1251' if StringTools.cp1251_compatible_encodings.include?(e)
    e
  end

  def to_utf8!
    self.replace(self.to_utf8)
  end

  def to_utf8
    # и так utf
    return self if is_utf8?

    enc = detect_encoding

    # если utf или английские буквы, то тоже ок
    return self if ['utf-8', 'ascii'].include?(enc)

    # если неизвестная каша, то возвращаем пустую строку
    return '' if enc.nil?

    # иначе пытаемся перекодировать
    encode 'utf-8', enc, :undef => :replace, :invalid => :replace
  rescue
    ''
  end

  def to_cp1251
    encode 'cp1251', :undef => :replace, :invalid => :replace
  rescue
    ''
  end

  def to_cp1251!
    self.replace(self.to_cp1251)
  end
end
