require 'thor/core_ext/hash_with_indifferent_access'
require 'contentful_middleman/tools/preview_proxy'
require 'structured_text_renderer'

module ContentfulMiddleman
  module Helpers
    def contentful_instances
      ContentfulMiddleman.instances
    end

    def localize_entry(entry, locale, fallback_locale='en-US')
      localized_entry = ::Thor::CoreExt::HashWithIndifferentAccess.new
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

    def structured_text(document_field, instance_index = 0)
      mappings = begin
                   app.extensions[:contentful]["instance_#{instance_index}"].options[:structured_text_mappings] || {}
                 rescue Exception
                   {}
                 end

      StructuredTextRenderer::Renderer.new(mappings).render(document_field)
    end
  end
end
