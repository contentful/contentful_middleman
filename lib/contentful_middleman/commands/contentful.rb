require 'middleman-core/cli'
require 'date'
require 'middleman-blog/uri_templates'

class TemplateContext < BasicObject
  def method_missing(symbol, *args, &block)
    if symbol =~ /.+=$/
      instance_eval "@#{symbol.to_s.gsub('=','')} = args.first"
    else
      instance_eval "@#{symbol}"
    end
  end

  def binding
    ::Kernel.binding
  end
end

class DelegatedRenderer
  def initialize(thor, template, path, context)
    @thor     = thor
    @path     = path
    @template = template
    @context  = context
  end

  def render
    @thor.create_file @path, nil, {} do
      ERB.new(::File.binread(File.expand_path(@template)), nil, '-', '@output_buffer').result(@context.binding)
    end
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

      def contentful
        contentful_middleman         = shared_instance.contentful_middleman
        client                       = shared_instance.contentful_middleman_client
        contentful_middleman_options = contentful_middleman.options


        client.entries(contentful_middleman_options.cda_query).each do |entry|
          context       = TemplateContext.new

          if (mapper = contentful_middleman_options.mapper)
            mapper.call context, entry if mapper.is_a? Proc
            mapper.map context, entry if mapper.respond_to? :map
          end

        end

        shared_instance.logger.info 'Contentful Import: Done!'
      end

      private
        def shared_instance
          @shared_instance ||= ::Middleman::Application.server.inst
        end
    end

  end
end
