require 'yaml'

module ContentfulMiddleman
  class DelegatedYAMLWritter
    def initialize(thor)
      @thor     = thor
    end

    def render(context, path)
      @thor.create_file path, nil, {} { context.to_hash.to_yaml }
    end

    def method_missing(symbol, *args, &block)
      @thor.send symbol, *args, &block
    end
  end
end
