require 'middleman-core/cli'
require 'date'
require 'middleman-blog/uri_templates'

class Context < BasicObject
  def initialize
    @_variables = {}
  end

  def method_missing(symbol, *args, &block)
    if symbol =~ /.+=$/
      variable_name              = symbol.to_s.gsub('=','')
      variable_value             = args.first

      set variable_name, variable_value
    else
      get symbol
    end
  end

  def set(name, value)
    @_variables[name] = value
  end

  def get(name)
    @_variables[name]
  end

  def to_hash
    @_variables
  end
end

class DelegatedYAMLRenderer
  def initialize(thor, path, context)
    @thor     = thor
    @path     = path
    @context  = context
  end

  def render
    @thor.create_file @path, nil, {} { @context.to_hash.to_yaml }
  end

  def method_missing(symbol, *args, &block)
    @thor.send symbol, *args, &block
  end
end


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

      def initialize(*args, options, &block)
        super

        @content_type_mappers = {}
      end

      def contentful
        client.entries(contentful_middleman_options.cda_query).each do |entry|
          context = Context.new
          mapper  = content_type_mapper entry.content_type.id

          mapper.map context, entry
        end

        shared_instance.logger.info 'Contentful Import: Done!'
      end

      private
        def shared_instance
          @shared_instance ||= ::Middleman::Application.server.inst
        end

        def content_type_mapper(content_type)
          @content_type_mappers[content_type] ||= begin
            content_type_options = contentful_middleman_options.content_types.fetch(content_type)
            mapper_class         = content_type_options.fetch(:mapper)
            mapper_class.new
          end
        end

        def contentful_middleman_options
          contentful_middleman.options
        end

        def contentful_middleman
          shared_instance.contentful_middleman
        end

        def client
          shared_instance.contentful_middleman_client
        end
    end

  end
end
