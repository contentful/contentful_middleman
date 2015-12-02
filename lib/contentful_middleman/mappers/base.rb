require_relative '../commands/context'

module ContentfulMiddleman
  module Mapper
    class Base
      attr_reader :entries

      def initialize(entries, options)
        @entries = entries
        @options = options
        @children = {}
      end

      def map(context, entry)
        @children = {
          :queue => [{ :context => context, :entry => entry }],
          :discovered => [entry.id] }
        while !@children[:queue].first.nil? do
          nxt = @children[:queue].pop
          context = nxt[:context]
          entry = nxt[:entry]
          map_entry_full(entry, context)
        end
      end

      private

      def has_multiple_locales?
        @options.cda_query.fetch(:locale, nil) == '*'
      end

      def map_field(context, field_name, field_value)
        value_mapping = map_value(field_value)
        context.set(field_name, value_mapping)
      end

      def map_value(value)
        case value
        when Contentful::Asset
          map_asset(value)
        when Contentful::Location
          map_location(value)
        when Contentful::Link
          map_link(value)
        when Contentful::DynamicEntry
          map_entry(value)
        when Array
          map_array(value)
        else
          value
        end
      end

      def map_asset(asset)
        context       = Context.new
        context.title = asset.title
        context.url   = asset.file.url

        context
      end

      def map_entry_full(entry, context)
        context.id = entry.id

        fields = has_multiple_locales? ? entry.fields_with_locales : entry.fields

        fields.each {|k, v| map_field context, k, v}
      end

      def map_entry(entry)
        context = Context.new
        context.id = entry.id
        if !@children[:discovered].include?(entry.id)
          @children[:queue].push({ :context => context, :entry => entry})
          @children[:discovered].push(entry.id)
        end
        context
      end

      def map_location(location)
        location.properties
      end

      def map_link(link)
        context    = Context.new
        context.id = link.id

        context
      end

      def map_array(array)
        array.map {|element| map_value(element)}
      end
    end
  end
end
