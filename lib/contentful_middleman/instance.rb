module ContentfulMiddleman
  class Instance
    API_PREVIEW_URL = 'preview.contentful.com'

    def initialize(extension)
      @extension = extension
    end

    def entries
      client.entries(options.cda_query)
    end

    def space_name
      @space_name ||= options.space.fetch(:name)
    end

    def content_types_ids_to_mappers
      @content_types_mappers ||= options.content_types.reduce({}) do |acc, (content_type_id, config)|
        content_type_mapper  = config.fetch(:mapper)
        acc[content_type_id] = content_type_mapper
        acc
      end
    end

    def content_types_ids_to_names
      @content_types_names ||= options.content_types.reduce({}) do |acc, (content_type_id, config)|
        content_type_name    = config.fetch(:name)
        acc[content_type_id] = content_type_name
        acc
      end
    end

    private
    def client
      @client ||= Contentful::Client.new(client_options)
    end

    def client_options
      client_options = {
          access_token:     options.access_token,
          space:            options.space.fetch(:id),
          dynamic_entries:  :auto,
          raise_errors:     true
      }

      client_options[:api_url] = API_PREVIEW_URL if options.use_preview_api
      client_options
    end

    def options
      @extension.options
    end
  end
end
