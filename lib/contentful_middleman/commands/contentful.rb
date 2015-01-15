require 'middleman-core/cli'
require 'middleman-blog/uri_templates'
require 'date'
require_relative 'context'
require_relative 'delegated_yaml_writter'

module Middleman
  module Cli
    # This class provides an "contentful" command for the middleman CLI.
    class Contentful < Thor
      include Thor::Actions

      check_unknown_options!

      namespace :contentful
      desc 'contentful', 'Import data from Contentful'

      def self.source_root
        ENV['MM_ROOT']
      end

      # Tell Thor to exit with a nonzero exit code on failure
      def self.exit_on_failure?
        true
      end

      def contentful
        yaml_renderer        = ContentfulMiddleman::DelegatedYAMLWritter.new(self)

        if shared_instance.respond_to? :contentful_instances
          contentful_instances = shared_instance.contentful_instances

          contentful_instances.each do |instance|
            instance.entries.each do |entry|
              context              = ContentfulMiddleman::Context.new
              mapper               = instance.content_type_mapper entry.content_type.id
              entry_data_file_path = data_file_path instance, entry

              mapper.map context, entry
              yaml_renderer.render context, entry_data_file_path
            end
          end

          shared_instance.logger.info 'Contentful Import: Done!'
        else
          raise Thor::Error.new "You need to activate the contentful extension in config.rb before you can import data from Contentful"
        end
      end

      private
        def shared_instance
          @shared_instance ||= ::Middleman::Application.server.inst
        end

        def data_file_path(instance, entry)
          data_path(
            instance.space_name,
            instance.content_type_name(entry.content_type.id),
            entry.id)
        end

        def data_path(space_name, content_type_name, entry_id)
          data_filename = "#{entry_id}.yaml"
          File.join(
            shared_instance.root_path.to_s,
            'data',
            space_name.to_s,
            content_type_name.to_s,
            data_filename)
        end
    end

  end
end
