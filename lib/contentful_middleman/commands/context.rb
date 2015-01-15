module ContentfulMiddleman
  class Context < BasicObject
    def initialize
      @_variables = {}
    end

    def method_missing(symbol, *args, &block)
      if symbol =~ /.+=$/
        variable_name              = symbol.to_s.gsub('=','')
        variable_value             = args.first

        set variable_name, variable_value
      else
        get symbol
      end
    end

    def set(name, value)
      @_variables[name] = value
    end

    def get(name)
      @_variables[name]
    end

    def to_hash
      @_variables
    end
  end
end
