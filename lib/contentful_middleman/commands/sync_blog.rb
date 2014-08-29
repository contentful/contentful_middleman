require 'middleman-core/cli'
require 'date'
require 'middleman-blog/uri_templates'

module Middleman
  module Cli
    # This class provides an "contentful" command for the middleman CLI.
    class SyncBlog < Thor
      include Thor::Actions
      include ::Middleman::Blog::UriTemplates

      check_unknown_options!

      namespace :contentful

      def self.source_root
        ENV['MM_ROOT']
      end

      # Tell Thor to exit with a nonzero exit code on failure
      def self.exit_on_failure?
        true
      end

      desc "contentful", "Synchronize Contentful blog posts"
      method_option "lang",
        aliases: "-l",
        desc: "The language to create the post with (defaults to I18n.default_locale if avaliable)"
      method_option "blog",
        aliases: "-b",
        desc: "The name of the blog to create the post inside (for multi-blog apps, defaults to the only blog in single-blog apps)"
      def contentful
        contentful_middleman = shared_instance.contentful_middleman
        client = shared_instance.contentful_middleman_client
        contentful_middleman_options = contentful_middleman.options
        blog_post_mappings = contentful_middleman.blog_post_mappings

        if shared_instance.respond_to? :blog
          shared_instance.logger.info "  Contentful Sync: Start..."


          client.entries(contentful_middleman_options.blog_posts_query).each do |entry|
            slug  = value_from_object(entry, blog_post_mappings[:slug])
            title = value_from_object(entry, blog_post_mappings[:title])
            date  = value_from_object(entry, blog_post_mappings[:date]).strftime("%Y-%m-%d")
            tags  = value_from_object(entry, blog_post_mappings[:tags]) || []
            body  = value_from_object(entry, blog_post_mappings[:body])

            @title = title
            @slug  = slug || safe_parameterize(title)
            @date  = date ? Time.zone.parse(date) : Time.zone.now
            @tags  = tags
            @lang  = options[:lang] || ( I18n.default_locale if defined? I18n )
            @body  = body

            if (mapper = contentful_middleman_options.mapper)
              mapper.call self, entry if mapper.is_a? Proc
              mapper.map self, entry if mapper.respond_to? :map
            end

            blog_inst = shared_instance.blog(options[:blog])

            path_template = blog_inst.source_template
            params = date_to_params(@date).merge(lang: @lang.to_s, title: @slug)
            article_path = apply_uri_template path_template, params

            template contentful_middleman.options.new_article_template, File.join(shared_instance.source_dir, article_path + blog_inst.options.default_extension)
          end

          shared_instance.logger.info " Contentful Sync: Done!"
        else
          raise Thor::Error.new "You need to activate the blog extension in config.rb before you can create an article"
        end
      end

      no_commands do
        def set_value(key, value)
          instance_variable_set "@#{key}".to_sym, value
        end
      end

      private
        def shared_instance
          @shared_instance ||= ::Middleman::Application.server.inst
        end

        def value_from_object(object, mapping)
          if ( mapping.is_a?(Symbol) || mapping.is_a?(String) ) && object.respond_to?(mapping)
            object.send(mapping)
          elsif mapping.is_a?(Proc)
            object.instance_exec(object, &mapping)
          else
            shared_instance.logger.warn "Warning - Unknown mapping (#{mapping}) for object (#{object.class}) with ID (#{object.id})"
            nil
          end
        end
    end

  end
end
