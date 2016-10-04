module ContentfulMiddleman
  class Context < BasicObject
    def initialize
      @variables = {}
    end

    def method_missing(symbol, *args, &block)
      if symbol =~ /\A.+=\z/
        variable_name  = symbol.to_s.gsub('=','')
        variable_value = args.first

        set variable_name, variable_value
      else
        get symbol
      end
    end

    def set(name, value)
      @variables[name.to_sym] = value
    end

    def get(name)
      @variables.fetch(name.to_sym)
    end

    def is_a?(klass)
      Context == klass
    end

    def to_yaml
      hashize.to_yaml
    end

    def hashize
      variables = @variables.dup
      variables.update(variables) do |variable_name, variable_value|
        ensure_primitive_data_types(variable_value)
      end
    end

    def ensure_primitive_data_types(value)
      case value
      when Context
        value.hashize
      when ::Array
        value.map {|element| ensure_primitive_data_types(element)}
      when ::Hash
        res = {}
        value.each do |k, v|
          res[ensure_primitive_data_types(k)] = ensure_primitive_data_types(v)
        end
        res
      else
        value
      end
    end
  end
end
