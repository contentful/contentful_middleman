module ContentfulMiddleman
  module Mapper
    class Base
      def map(context, entry)
        map_entry(context, entry)
      end

      private
      def map_entry(context, entry)
        context.id = entry.id
        entry.fields.each {|k, v| map_field context, k, v}
      end

      def map_field(context, field_name, field_value)
        case field_value
        when Contentful::Asset
          map_asset(context, field_name, field_value)
        when Contentful::Location
          map_location(context, field_name, field_value)
        when Array
          map_array(context, field_name, field_value)
        else
          context.set(field_name, field_value)
        end
      end

      def map_asset(context, field_name, field_value)
        context.nest(field_name) do |nested_context|
          nested_context.title = field_value.title
          nested_context.url   = field_value.file.url
        end
      end

      def map_array(context, field_name, field_value)
          context.map(field_name, field_value) do |element, new_context|
            map_entry(new_context, element)
          end
      end

      def map_location(context, field_name, field_value)
        context.set(field_name, field_value.properties)
      end
    end
  end
end
