require 'middleman-core'
require 'contentful'

# The Contentful Middleman extensions allows to load managed content into Middleman projects through the Contentful Content Management Platform.
module ContentfulMiddleman
  class Core < ::Middleman::Extension
    self.supports_multiple_instances = false

    option :space, nil,
      'The Contentful Space ID'

    option :access_token, nil,
      'The Contentful Content Delivery API access token'

    option :cda_query, {},
      'The conditions that are used on the Content Delivery API to query for blog posts'

    option :mapper, nil,
      'Use a custom mapper to do the translation from the Contentful DynamicResources to Middleman'

    def initialize(app, options_hash={}, &block)
      super

      app.set :contentful_middleman, self
      app.set :contentful_middleman_client, client
    end

    # The Contentful Gem client for the Content Delivery API
    def client
      @client ||= Contentful::Client.new(
        access_token:     options.access_token,
        space:            options.space,
        dynamic_entries:  :auto
      )
    end

    helpers do
      # A helper method to access the Contentful Gem client
      def contentful
        contentful_middleman_client
      end
    end
  end
end
