require 'logger'
require 'middleman-core'
require 'contentful'
require 'contentful/webhook/listener'
require_relative 'mappers/base'
require_relative 'helpers'
require_relative 'instance'
require_relative 'webhook_handler'

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

    option :cda_query, {},
      'The conditions that are used on the Content Delivery API to query for blog posts'

    option :content_types, {},
      'The mapping of Content Types names to ids'

    option :use_preview_api, false,
      'Use the Preview API when fetching content'

    option :all_entries, false,
      'Allow multiple requests to the API for getting over 1000 entries'

    option :rebuild_on_webhook, false,
      "Run `middleman contentful --rebuild` upon receiving a Webhook on http://0.0.0.0:5678/receive"

    option :webhook_timeout, 300,
      "Wait time before rebuild after receiving a Webhook call"

    option :webhook_controller, ::ContentfulMiddleman::WebhookHandler,
      "Controller for managing Webhook callbacks"


    helpers ContentfulMiddleman::Helpers

    attr_reader :middleman_app
    def initialize(app, options_hash = {}, &block)
      super
      @middleman_app = app

      this = self # Hack due to context change
      app.before_server do
        this.webhook_options
      end
    end

    #
    # Middleman hooks
    #
    def after_configuration
      massage_options

      ContentfulMiddleman.instances << (ContentfulMiddleman::Instance.new self)
    end

    def webhook_options
      ::ContentfulMiddleman::WebhookHandler.start(options) if options.rebuild_on_webhook
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
