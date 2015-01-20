require 'middleman-core/cli'
require 'middleman-blog/uri_templates'
require 'date'
require 'digest'
require_relative 'context'
require_relative 'delegated_yaml_writter'

module Middleman
  module Cli
    # This class provides an "contentful" command for the middleman CLI.

    class VersionHash
      def self.read_for_space(space_name)
        hashfilename_for_space = hashfilename(space_name)
        ::File.read(hashfilename_for_space) if File.exist? hashfilename_for_space
      end

      def self.write_for_space_with_entries(space_name, entries)
        sorted_entries           = entries.sort {|a, b| a.id <=> b.id}
        ids_and_revisions_string = sorted_entries.map {|e| "#{e.id}#{e.revision}"}.join
        entries_hash             = Digest::SHA1.hexdigest( ids_and_revisions_string )

        File.open(hashfilename(space_name), 'w') { |file| file.write(entries_hash) }

        entries_hash
      end

      def self.hashfilename(space_name)
        ::File.join(Contentful.source_root, ".#{space_name}-space-hash")
      end
    end


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
            remove_data_files(instance)
            old_version_hash = VersionHash.read_for_space(instance.space_name)

            entries =  instance.entries
            entries.each do |entry|
              context              = ContentfulMiddleman::Context.new
              mapper               = instance.content_type_mapper entry.content_type.id
              entry_data_file_path = data_file_path instance, entry

              mapper.map context, entry
              yaml_renderer.render context, entry_data_file_path
            end

            new_version_hash = VersionHash.write_for_space_with_entries(instance.space_name, entries)

            if new_version_hash != old_version_hash
              p "Needs rebuild"
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

        def remove_data_files(instance)
          Dir["data/#{instance.space_name}/**/*"].each do |file|
            remove_file file
          end
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
