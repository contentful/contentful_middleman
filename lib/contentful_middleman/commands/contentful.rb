require 'middleman-core/cli'
require 'date'
require 'digest'
require 'contentful_middleman/commands/context'
require 'contentful_middleman/tools/backup'
require 'contentful_middleman/version_hash'
require 'contentful_middleman/import_task'
require 'contentful_middleman/local_data/store'
require 'contentful_middleman/local_data/file'

module Middleman
  module Cli
    # This class provides an "contentful" command for the middleman CLI.

    class Contentful < Thor
      include Thor::Actions

      # Path where Middleman expects the local data to be stored
      MIDDLEMAN_LOCAL_DATA_FOLDER = 'data'

      check_unknown_options!

      namespace :contentful
      desc 'contentful', 'Import data from Contentful'

      method_option "rebuild",
        aliases: "-r",
        desc: "Rebuilds the site if there were changes in the imported data"

      def self.source_root
        ENV['MM_ROOT']
      end

      # Tell Thor to exit with a nonzero exit code on failure
      def self.exit_on_failure?
        true
      end

      def contentful
        if shared_instance.respond_to? :contentful_instances
          ContentfulMiddleman::VersionHash.source_root    = self.class.source_root
          ContentfulMiddleman::LocalData::Store.base_path = MIDDLEMAN_LOCAL_DATA_FOLDER
          ContentfulMiddleman::LocalData::File.thor       = self

          hash_local_data_changed = contentful_instances.reduce(false) do |changes, instance|
            import_task = create_import_task(instance)
            import_task.run

            changes || import_task.changed_local_data?
          end

          Middleman::Cli::Build.new.build if hash_local_data_changed && options[:rebuild]
          shared_instance.logger.info 'Contentful Import: Done!'
        else
          raise Thor::Error.new "You need to activate the contentful extension in config.rb before you can import data from Contentful"
        end
      end

      private
        def contentful_instances
          shared_instance.contentful_instances
        end

        def create_import_task(instance)
          space_name           = instance.space_name.to_s
          content_type_names   = instance.content_types_ids_to_names
          content_type_mappers = instance.content_types_ids_to_mappers

          ContentfulMiddleman::ImportTask.new(space_name, content_type_names, content_type_mappers, instance)
        end

        def shared_instance
          @shared_instance ||= ::Middleman::Application.server.inst do
            set :environment, :contentful
          end
        end
    end

  end
end
