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
        if has_multiple_locales?
          processed_locales = {}
          field_value.each do |locale, value|
            processed_locales[locale] = map_value(value, locale.to_s)
          end
          context.set(field_name, processed_locales)
        else
          value_mapping = map_value(field_value)
          context.set(field_name, value_mapping)
        end
      end

      def map_value(value, locale = nil)
        case value
        when Contentful::Asset
          map_asset(value, locale)
        when Contentful::Location
          map_location(value)
        when Contentful::Link
          map_link(value)
        when Contentful::Entry
          map_entry(value)
        when Array
          map_array(value, locale)
        else
          value
        end
      end

      def map_asset_metadata(asset)
        context = Context.new
        context.updated_at = asset.sys[:updated_at].iso8601 unless asset.sys[:updated_at].nil?
        context.created_at = asset.sys[:created_at].iso8601 unless asset.sys[:created_at].nil?
        context.id = asset.sys[:id]

        context
      end

      def map_asset(asset, locale = nil)
        context = Context.new
        if locale
          context.title = asset.fields(locale)[:title]
          context.description = asset.fields(locale)[:description]
          context.url = asset.fields(locale)[:file].url unless asset.fields(locale)[:file].nil?
        end

        context.title = asset.title unless context.has?(:title) && !context.title.nil?
        context.description = asset.description unless context.has?(:description) && !context.description.nil?
        context.url = asset.url unless asset.file.nil? || (context.has?(:url) && !context.url.nil?)

        context._meta = map_asset_metadata(asset)

        context
      end

      def map_entry_metadata(entry)
        context = Context.new
        context.content_type_id = entry.sys[:content_type].id unless entry.sys[:content_type].nil?
        context.updated_at = entry.sys[:updated_at].iso8601 unless entry.sys[:updated_at].nil?
        context.created_at = entry.sys[:created_at].iso8601 unless entry.sys[:created_at].nil?
        context.id = entry.sys[:id]

        context
      end

      def map_entry_full(entry, context)
        context.id = entry.id
        context._meta = map_entry_metadata(entry)

        fields = has_multiple_locales? ? entry.fields_with_locales : entry.fields

        # Prevent entries with no values from breaking the import
        fields ||= {}

        fields.each {|k, v| map_field context, k, v}
      end

      def map_entry(entry)
        context = Context.new
        context.id = entry.id
        @children[:discovered].push(entry.id) unless @children[:discovered].include?(entry.id)
        @children[:queue].push({ :context => context, :entry => entry})
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

      def map_array(array, locale = nil)
        array.map {|element| map_value(element, locale)}
      end
    end
  end
end
