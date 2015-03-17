require 'middleman-core'
require 'contentful'
require_relative 'mappers/base'
require_relative 'helpers'
require_relative 'instance'

# The Contentful Middleman extensions allows to load managed content into Middleman projects through the Contentful Content Management Platform.
module ContentfulMiddleman
  def self.instances
    @contentful_middleman_instances ||= []
  end

  class Core < ::Middleman::Extension
    self.supports_multiple_instances = true

    option :space, nil,
      'The Contentful Space ID and name'

    option :access_token, nil,
      'The Contentful Content Delivery API access token'

    option :api_url, nil,
      'The Contentful Content Delivery API URL'

    option :cda_query, {},
      'The conditions that are used on the Content Delivery API to query for blog posts'

    option :content_types, {},
      'The mapping of Content Types names to ids'


    helpers ContentfulMiddleman::Helpers

    #
    # Middleman hooks
    #
    def after_configuration
      massage_options

      ContentfulMiddleman.instances << (ContentfulMiddleman::Instance.new self)
    end

    private
    def massage_options
      massage_space_options
      massage_content_types_options
    end

    def massage_space_options
      space_option          = options.space
      space_name            = space_option.keys.first
      space_id              = space_option.fetch(space_name)

      options.space = { name: space_name, id: space_id }
    end

    def massage_content_types_options
      content_types_options     = options.content_types
      new_content_types_options = content_types_options.each_with_object({}) do |(content_type_name, value), options|
        if value.is_a? Hash
          mapper = value.fetch(:mapper)
          id     = value.fetch(:id)
        else
          mapper = Mapper::Base
          id     = value
        end

        options[id] = {name: content_type_name, mapper: mapper}
      end

      options.content_types = new_content_types_options
    end
  end
end
