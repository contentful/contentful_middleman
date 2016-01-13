require 'middleman-cli'
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

    class Contentful < Thor::Group
      include Thor::Actions

      # Path where Middleman expects the local data to be stored
      MIDDLEMAN_LOCAL_DATA_FOLDER = 'data'

      check_unknown_options!

      class_option "rebuild",
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
        if contentful_instances.size > 0
          ContentfulMiddleman::VersionHash.source_root    = self.class.source_root
          ContentfulMiddleman::LocalData::Store.base_path = MIDDLEMAN_LOCAL_DATA_FOLDER
          ContentfulMiddleman::LocalData::File.thor       = self

          hash_local_data_changed = contentful_instances.reduce(false) do |changes, instance|
            import_task = create_import_task(instance)
            import_task.run

            changes || import_task.changed_local_data?
          end

          Middleman::Cli::Build.new.build if hash_local_data_changed && options[:rebuild]
          logger.info 'Contentful Import: Done!'
        else
          raise Thor::Error.new "You need to activate the contentful extension in config.rb before you can import data from Contentful"
        end
      end

      private
      def logger
        ::Middleman::Logger.singleton
      end

      def contentful_instances
        app.contentful_instances
      end

      def app
        @app ||= ::Middleman::Application.new do
          config[:mode] = :contentful
        end
      end

      def create_import_task(instance)
        space_name           = instance.space_name.to_s
        content_type_names   = instance.content_types_ids_to_names
        content_type_mappers = instance.content_types_ids_to_mappers

        ContentfulMiddleman::ImportTask.new(space_name, content_type_names, content_type_mappers, instance)
      end

      Base.register(self, 'contentful', 'contentful [--rebuild]', 'Import Contentful data to your Data folder')
    end
  end
end
