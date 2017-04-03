module StringTools
  class String
    TRUE_VALUES = %w(1 t T true TRUE on ON).to_set

    def initialize(string)
      @string = string
    end

    # Public: cast string value to boolean
    #
    # Example:
    #   StringTools::String.new('t').to_b
    #   #=> true
    #
    # Return boolean
    def to_b
      TRUE_VALUES.include?(@string)
    end
  end
end
