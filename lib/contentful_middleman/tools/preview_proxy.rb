require 'contentful'

module ContentfulMiddleman
  module Tools
    class PreviewProxy < ::Contentful::Client
      @@instances = []
      def self.instance(space: '', access_token: '', api_url: 'preview.contentful.com', tries: 3, expires_in: hours(2))
        possible_instance = @@instances.detect { |i| i[:space] == space && i[:access_token] == access_token }
        if possible_instance.nil?
          preview_client = PreviewProxy.new(space: space, access_token: access_token, api_url: api_url, tries: tries, expires_in: expires_in)
          @@instances << {space: space, access_token: access_token, instance: preview_client}
        else
          preview_client = possible_instance[:instance]
        end

        preview_client
      end

      def self.days(amount)
        amount
      end

      def self.hours(amount)
        amount / 24.0
      end

      def self.minutes(amount)
        hours(amount) / 60.0
      end

      def self.seconds(amount)
        minutes(amount) / 60.0
      end

      CACHE_MAPPINGS = {
        entries: {
          cache: :cached_entry_collection
        },
        assets: {
          cache: :cached_asset_collection
        },
        entry: {
          cache: :cached_entries
        },
        asset: {
          cache: :cached_assets
        }
      }

      def initialize(space: '', access_token: '', api_url: 'preview.contentful.com', tries: 3, expires_in: self.class.hours(2))
        super(
          space: space,
          access_token: access_token,
          dynamic_entries: :auto,
          preview: true,
          api_url: api_url
        )

        @cache_tries = tries
        @expires_in = expires_in

        clear_cache
      end

      def entries(query = {})
        cache(:entries, ->(q, _) { super(q) }, query)
      end

      def entry(id, query = {})
        cache(:entry, ->(q, e_id) { super(e_id, q) }, query, id)
      end

      def assets(query = {})
        cache(:assets, ->(q, _) { super(q) }, query)
      end

      def asset(id, query = {})
        cache(:asset, ->(q, a_id) { super(a_id, q) }, query, id)
      end

      def clear_cache
        @cached_entry_collection = {}
        @cached_asset_collection = {}

        @cached_entries = {}
        @cached_assets = {}
      end

      private

      def cache(name, super_call, query = {}, id = '')
        mapping = CACHE_MAPPINGS[name]
        query_copy = Marshal.load(Marshal.dump(query))

        if should_fetch_from_api?(name, query: query_copy, id: id)
          new_resources = super_call.call(query, id)
          instance_variable_get("@#{mapping[:cache]}")[cache_key(name, query_copy, id)] ||= {}
          instance_variable_get("@#{mapping[:cache]}")[cache_key(name, query_copy, id)][:tries] = 0
          instance_variable_get("@#{mapping[:cache]}")[cache_key(name, query_copy, id)][:expires] = DateTime.now + @expires_in
          instance_variable_get("@#{mapping[:cache]}")[cache_key(name, query_copy, id)][:data] = new_resources
          return new_resources
        end

        instance_variable_get("@#{mapping[:cache]}")[cache_key(name, query_copy, id)][:tries] += 1
        instance_variable_get("@#{mapping[:cache]}")[cache_key(name, query_copy, id)][:data]
      end


      def cache_key(name, query = {}, id = '')
        Marshal.dump(collection?(name) ? query : query.merge(cache_id: id))
      end

      def collection?(name)
        name.to_s.end_with?('s')
      end

      def should_fetch_from_api?(name, query: {}, id: '')
        mapping = CACHE_MAPPINGS[name]

        cache = instance_variable_get("@#{mapping[:cache]}")
        key = cache_key(name, query, id)

        return true unless cache.key?(key)
        return true if cache[key][:tries] >= @cache_tries
        return true if cache[key][:expires] <= DateTime.now

        false
      end
    end
  end
end
