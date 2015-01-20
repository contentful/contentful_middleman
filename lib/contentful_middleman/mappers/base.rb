module ContentfulMiddleman
  module Mapper
    class Base
      def map(context, entry)
        context.id = entry.id
        entry.fields.each {|k, v| map_field context, k, v}
      end

      private
      def map_field(context, field_name, field_value)
        case field_value
        when Contentful::Asset
          context.nest(field_name) do |nested_context|
            nested_context.title = field_value.title
            nested_context.url   = field_value.file.url
          end
        else
          context.set field_name, field_value
        end
      end
    end
  end
end
