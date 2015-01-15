module ContentfulMiddleman
  module Mapper
    class Base
      def map(context, entry)
        entry.fields.each {|k, v| context.set k, v}
      end
    end
  end
end
