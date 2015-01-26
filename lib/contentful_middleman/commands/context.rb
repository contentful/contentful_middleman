module ContentfulMiddleman
  class Context < BasicObject
    def initialize
      @variables       = {}
      @nexted_contexts = []
    end

    def method_missing(symbol, *args, &block)
      if symbol =~ /\A.+=\z/
        variable_name              = symbol.to_s.gsub('=','')
        variable_value             = args.first

        set variable_name, variable_value
      else
        get symbol
      end
    end

    def nest(field_name)
      @nexted_contexts << field_name
      new_context = Context.new
      yield new_context

      set field_name, new_context
    end

    def map(field_name, elements)
      @nexted_contexts << field_name
      new_contexts = elements.map do |element|
        new_context = Context.new
        yield element, new_context
        new_context
      end

      set field_name, new_contexts
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

    def to_hash
      @variables
    end

    def to_yaml
      variables = @variables.dup
      variables.update(variables) do |variable_name, variable_value|
        if @nexted_contexts.include? variable_name
          hashize_nested_context(variable_value)
        else
          variable_value
        end
      end

      variables.to_yaml
    end

    def hashize_nested_context(nested_context)
      case nested_context
      when ::Array
        nested_context.map {|e| e.to_hash}
      else
        nested_context.to_hash
      end
    end
  end
end
