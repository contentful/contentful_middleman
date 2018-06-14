require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('lib', __FILE__)

require 'vcr'
require 'yaml'

require 'contentful_middleman'
require 'middleman-core'

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_fixtures"
  config.hook_into :webmock
end

def vcr(cassette)
  VCR.use_cassette(cassette) do
    yield if block_given?
  end
end

def yaml(name)
  yaml = YAML.parse(File.read("spec/fixtures/yaml_fixtures/#{name}.yaml")).to_ruby
  yield yaml if block_given?
  yaml
end

class ServerDouble
  def [](key)
  end
end

class RequestDouble
  attr_accessor :query
end

class ResponseDouble
  attr_accessor :body, :status, :content_type
end

class OptionsDouble
  DEFAULT_OPTIONS = {
    space: {id: 'cfexampleapi', name: 'cats'},
    access_token: 'b4c0n73n7fu1',
    cda_query: {},
    client_options: {},
    content_types: {},
    default_locale: 'en-US',
    use_preview_api: false,
    all_entries: false,
    all_entries_page_size: 1000,
    rebuild_on_webhook: false,
    webhook_timeout: 300,
    webhook_controller: ::ContentfulMiddleman::WebhookHandler
  }

  def initialize(options = {})
    options = DEFAULT_OPTIONS.merge(options)
    options.each do |field, value|
      define_singleton_method(field.to_sym) do
        value
      end

      define_singleton_method("#{field}=".to_sym) do |v|
        options[field] = v
      end
    end
  end
end

class ContentTypeDouble
  attr_reader :id

  def initialize(id)
    @id = id
  end
end

class EntryDouble
  attr_reader :id, :sys, :fields

  def initialize(id, sys_data = {}, fields = {}, updated_at = nil, camel_case = false)
    @id = id
    sys_data[:id] = id
    sys_data[camel_case ? :updatedAt : :updated_at] = updated_at
    sys_data[camel_case ? :contentType : :content_type] = ContentTypeDouble.new("#{id}_ct")
    @sys = sys_data
    @fields = fields
    @camel_case = camel_case

    sys_data.each do |k, v|
      define_singleton_method k do
        v
      end
    end

    unless fields.nil?
      fields.each do |k, v|
        define_singleton_method k do
          v
        end
      end
    end
  end
end
