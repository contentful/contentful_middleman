require 'contentful_middleman/tools/preview_proxy'

module ContentfulMiddleman
  module Helpers
    def contentful_instances
      ContentfulMiddleman.instances
    end

    def localize_entry(entry, locale, fallback_locale='en-US')
      localized_entry = {}
      entry.each do |field, value|
        localized_entry[field] = localize(entry, field, locale, fallback_locale)
      end
      localized_entry
    end

    def localize(entry, field, locale, fallback_locale='en-US')
      value = entry.fetch(field)

      return localize_array(value, locale, fallback_locale) if value.is_a? ::Array
      localize_value(value, locale, fallback_locale)
    end

    def localize_array(value, locale, fallback_locale='en-US')
      value.map do |v|
        localize_value(v, locale, fallback_locale)
      end
    end

    def localize_value(value, locale, fallback_locale='en-US')
      if value.respond_to? :fetch
        return value.fetch(locale) if value.key? locale
        return value.fetch(fallback_locale)
      end
      value
    end

    def with_preview(space: '', access_token: '', tries: 3, expires_in: ContentfulMiddleman::Tools::PreviewProxy.hours(2), &block)
      preview_client = ContentfulMiddleman::Tools::PreviewProxy.instance(
        space: space,
        access_token: access_token,
        tries: tries,
        expires_in: expires_in
      )

      block.call(preview_client)
    end
  end
end
