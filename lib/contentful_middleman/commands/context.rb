module ContentfulMiddleman
  class Context < BasicObject
    def initialize
      @_variables       = {}
      @_nested_contexts = []
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

    def nest(field_name)
      @_nested_contexts << field_name
      new_context = Context.new
      yield new_context
      set field_name, new_context
    end

    def set(name, value)
      @_variables[name.to_sym] = value
    end

    def get(name)
      @_variables[name.to_sym]
    end

    def to_hash
      variables = @_variables.dup
      variables.update(variables) do |k,v|
        if @_nested_contexts.include? k
          v.to_hash
        else
          v
        end
      end
    end
  end
end
