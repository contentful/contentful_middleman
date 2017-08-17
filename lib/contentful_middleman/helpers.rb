require 'contentful_middleman/tools/preview_proxy'

module ContentfulMiddleman
  module Helpers
    def contentful_instances
      ContentfulMiddleman.instances
    end

    def localize_entry(entry, locale, fallback_locale='en-US')
      localized_entry = entry.class.new
      localized_entry = {} unless localized_entry.is_a? ::Hash
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
      value = value.fetch(locale) if value.respond_to?(:fetch) && value.respond_to?(:key?) && value.key?(locale)
      value = value.fetch(fallback_locale) if value.respond_to?(:fetch) && value.respond_to?(:key?) && value.key?(fallback_locale)

      return localize_array(value, locale, fallback_locale) if value.is_a? ::Array
      return localize_entry(value, locale, fallback_locale) if value.is_a? ::Hash
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
