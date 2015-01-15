module ContentfulMiddleman
  class Instance
    def initialize(extension)
      @extension            = extension
      @content_type_mappers = {}
    end

    def entries
      client.entries(options.cda_query)
    end

    def content_type_mapper(content_type)
      @content_type_mappers[content_type] ||= begin
        content_type_options = options.content_types.fetch(content_type)
        mapper_class         = content_type_options.fetch(:mapper)
        mapper_class.new
      end
    end

    def space_name
      @space_name ||= options.space.fetch(:name)
    end

    def content_type_name(content_type_id)
      options.content_types.fetch(content_type_id).fetch(:name)
    end

    private
    def client
      @client ||= Contentful::Client.new(
        access_token:     options.access_token,
        space:            options.space.fetch(:id),
        dynamic_entries:  :auto
      )
    end

    def options
      @extension.options
    end
  end
end
