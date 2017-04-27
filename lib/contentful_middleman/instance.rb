module ContentfulMiddleman
  class Instance
    API_PREVIEW_URL = 'preview.contentful.com'

    def initialize(extension)
      @extension = extension
    end

    def entries
      if options.all_entries
        all_entries(options.cda_query)
      else
        client.entries(options.cda_query)
      end
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

    def options
      @extension.options
    end

    private

    def all_entries(cda_query)
      all = []
      query = cda_query.clone
      query[:order] = 'sys.createdAt' unless query.key?(:order)
      num_entries = client.entries(limit: 1).total

      ((num_entries / options.all_entries_page_size) + 1).times do |i|
        query[:limit] = options.all_entries_page_size
        query[:skip] = i * options.all_entries_page_size
        page = client.entries(query)
        page.each { |entry| all << entry }
      end

      all
    end

    def client
      @client ||= Contentful::Client.new(client_options)
    end

    def client_options
      client_options = {
          access_token:     options.access_token,
          space:            options.space.fetch(:id),
          dynamic_entries:  :auto,
          raise_errors:     true,
          default_locale:   options.default_locale
      }.merge(options.client_options)

      client_options[:api_url] = API_PREVIEW_URL if options.use_preview_api
      client_options
    end
  end
end
