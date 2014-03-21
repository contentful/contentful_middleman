require 'middleman-core'
require 'contentful'

# The Contentful Middleman extensions allows to load managed content into Middleman projects through the Contentful Content Management Platform.
module ContentfulMiddleman
  class Core < ::Middleman::Extension
    DEFAULT_BLOG_MAPPINGS = {
      slug: :id,
      date: :created_at,
      title: :id,
      body: :id,
      tags: :tags
    }

    self.supports_multiple_instances = false

    option :space, nil, 'The Contentful Space ID'
    option :access_token, nil, 'The Contentful Content Delivery API access token'

    option :new_article_template, File.expand_path('../commands/article.tt', __FILE__), 'Path (relative to project root) to an ERb template that will be used to generate new Contentful articles from the "middleman contentful" command.'

    option :blog_posts_query, {}, "The conditions that are used on the Content Delivery API to query for blog posts"
    option :blog_post_mappings, {}, "The mappings from Contentful DynamicResources to Middleman"

    option :sync_blog_before_build, true, "Synchronize the blog from Contentful before the build phase"

    def initialize(app, options_hash={}, &block)
      super

      app.set :contentful_middleman, self
      app.set :contentful_middleman_client, client

      app.before_build do |builder|
        contentful_middleman.sync_blog if contentful_middleman.middleman_blog_enabled? && contentful_middleman.options.sync_blog_before_build
      end
    end

    # Is the Middleman blog extension enabled?
    def middleman_blog_enabled?
      app.respond_to? :blog
    end

    # Synchronize blog posts from Contentful through the CLI task
    def sync_blog
      Middleman::Cli::SyncBlog.new.contentful
      true
    end

    def blog_post_mappings
      @blog_post_mappings ||= ContentfulMiddleman::Core::DEFAULT_BLOG_MAPPINGS.merge(options.blog_post_mappings)
    end

    # The Contentful Gem client for the Content Delivery API
    def client
      @client ||= Contentful::Client.new(
        access_token: options.access_token,
        space: options.space,
        dynamic_entries: :auto
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
