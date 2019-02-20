# Contentful Middleman

[![Build Status](https://travis-ci.org/contentful/contentful_middleman.svg?branch=master)](https://travis-ci.org/contentful/contentful_middleman)

[Contentful](https://www.contentful.com) provides a content infrastructure for digital teams to power content in websites, apps, and devices. Unlike a CMS, Contentful was built to integrate with the modern software stack. It offers a central hub for structured content, powerful management and delivery APIs, and a customizable web app that enable developers and content creators to ship digital products faster.

Contentful Middleman is a [Middleman](http://middlemanapp.com/) extension to use the Middleman static site generator together with [Contentful](https://www.contentful.com). It is powered by the [Contentful Ruby Gem](https://github.com/contentful/contentful.rb).

Experience the power of Middleman while staying sane as a developer by letting end-users edit content in a web-based interface.

> The main release works for Middleman v4 starting on version `4.0.0`.
>
> If you are using Middleman v3, use older releases. Latest stable release is `3.0.0`


## Installation
Add the following line to the Gemfile of your Middleman project:

```
gem "contentful_middleman"
```

Then as usual, run:

```
bundle install
```

## Usage

Run `middleman contentful` in your terminal. This will fetch entries for the configured
spaces and content types and put the resulting data in the
[local data folder](https://middlemanapp.com/advanced/local-data/) as yaml files.

### --rebuild option

The `contentful` command has a `--rebuild` option which will trigger a rebuild of your site only if there were changes between the last
and the current import.

## Configuration

To configure the extension, add the following configuration block to Middleman's config.rb:

```ruby
activate :contentful do |f|
  f.space         = SPACE
  f.env           = CONTENTFUL_ENV
  f.access_token  = ACCESS_TOKEN
  f.cda_query     = QUERY
  f.content_types = CONTENT_TYPES_MAPPINGS
end
```

Parameter                | Description
----------               | ------------
space                    | Hash with an user choosen name for the space as key and the space id as value.
env                      | Contentful Space's Environment. (default: master)
access_token             | Contentful Delivery API access token.
cda_query                | Hash describing query configuration. See [contentful.rb](https://github.com/contentful/contentful.rb) for more info (look for filter options there). Note that by default only 100 entries will be fetched, this can be configured to up to 1000 entries using the `limit` option. Example: `f.cda_query = { limit: 1000 }`.
client_options           | Hash describing client configuration. See [contentful.rb](https://github.com/contentful/contentful.rb#client-configuration-options) for more info. This option should commonly be used to change Rate Limit Management, Include Resolution, Logging and Proxies.
content_types            | Hash describing the mapping applied to entries of the imported content types.
default_locale           | String with the value for the default locale for your space. Defaults to `'en-US'`.
use_preview_api          | Boolean to toggle the used API. Set it to `false` to use `cdn.contentful.com` (default value). Set it to `true` to use `preview.contentful.com`. More info in [the documentation](https://www.contentful.com/developers/documentation/content-delivery-api/#preview-api)
all_entries              | Boolean to toggle multiple requests to the API for getting over 1000 entries. This uses a naive approach and can get rate limited. When using this, have in mind adding an `order` in your `:cda_query` . Default order is `order: 'sys.createdAt'`.
all_entries_page_size    | Integer amount of items per page for `:all_entries` requests, allowing for smaller page sizes on content heavy requests.
rebuild_on_webhook       | Boolean to toggle Webhook server. Server will run in port 5678, and will be expecting to receive Contentful Webhook calls on `/receive`.
webhook_timeout          | Integer (in seconds) for wait time after Webhook received for rebuilding. Only used if `:rebuild_on_webhook` is true. Defaults to 300 seconds.
webhook_controller       | Class for handling Webhook response, defaults to `::ContentfulMiddleman::WebhookHandler`.
rich_text_mappings       | Hash with `'nodeType' => RendererClass` pairs determining overrides for the [`RichTextRenderer` library](https://github.com/contentful/rich-text-renderer.rb) configuration.
base_path                | String with path to your Middleman Application, defaults to current directory. Path is relative to your current location.
destination              | String with path within your base path under which to store the output yaml files. Defaults to `data`.

You can activate the extension multiple times to import entries from different spaces.

## Entry mapping

The extension will transform every fetched entry before storing it as a yaml file in the local
data folder. If a custom mapper is not specified a default one will be used.

The default mapper will map fields, assets and linked entries.

### Custom mappers

You can create your own mappers if you need so. The only requirements for a class to behave as a
mapper are an initializer and a `map(context, entry)` instance method.

The initializer takes two parameters:

  * A `Contentful::Array` of all entries for the current content model
  * A `Middleman::Configuration::ConfigurationManager` object containing the Contentful configuration options set in `config.rb`

[See BackrefMapper](https://github.com/contentful/contentful_middleman/blob/master/examples/mappers/backref.rb)
for an example use of entries.

[See the Base mapper](https://github.com/contentful/contentful_middleman/blob/master/lib/contentful_middleman/mappers/base.rb)
for an example use of options.

The `map` method takes two parameters:

  * A context object. All properties set on this object will be written to the yaml file
  * An entry

Following is an example of such custom mapper:

```ruby
class MyAwesomeMapper
  def initialize(entries, options)
    @entries = entries
    @options = options
  end

  def map(context, entry)
    context.slug = entry.title.parameterize
    #... more transformations
  end
end
```

If you don't want to map all the fields by hand inherit from the Base mappper:

```ruby
class MyAwesomeMapper < ContentfulMiddleman::Mapper::Base
  def map(context, entry)
    super
    # After calling super the context object
    # will have a property for every field in the
    # entry
  end
end
```

There's also an example back-reference mapper in the examples directory for adding back-references onto entries that are linked to by other entries.

#### Multiple Mappers

If you want to process a Content Type with multiple mappers, you can use the [Composite Design Pattern](https://en.wikipedia.org/wiki/Composite_pattern).
The Mapper code should look something similar to the following.

Then you can attach as many Custom Mappers as you want to that one.

```ruby
class CompositeMapper < ContentfulMiddleman::Mapper::Base
  @@mappers = []
  def self.mappers
    @@mappers
  end

  def map(context, entry)
    super
    mappers.each do |m|
      m.map(context, entry)
    end
  end
end
```

Then in your config.rb file:

```ruby
CompositeMapper.mappers << YourMapper.new
CompositeMapper.mappers << OtherMapper.new

activate :contentful do |f|
  '... your config here ...'
  f.content_types = {content_type_name_you_want_to_map: {mapper: CompositeMapper, id: 'content_type_id'}}
end
```

*NOTE*: This kind of Composite Mapper is static, therefore if you want to have multiple combinations of mappers
 for multiple entries, you'd need to write code a bit differently.

### Rich Text *BETA*

To render rich text in your views, you can use the `rich_text` view helper.

An example using `erb`:

```erb
<% data.my_space.my_type.each do |_, entry| %>
  <%= rich_text(entry.rich_field) %>
<% end %>
```

This will output the generated HTML generated by the [`RichTextRenderer` library](https://github.com/contentful/rich-text-renderer.rb).

#### Adding custom renderers

When using rich text, if you're planning to embed entries, then you need to create your custom renderer for them. You can read how create your own renderer classes [here](https://github.com/contentful/rich-text-renderer.rb#using-different-renderers).

To configure the mappings, you need to add them in your `activate` block like follows:

```ruby
activate :contentful do |f|
  # ... all the regular config ...
  f.rich_text_mappings = { 'embedded-entry-block' => MyCustomRenderer }
end
```

You can also add renderers for all other types of nodes if you want to have more granular control over the rendering.

#### Using the helper with multiple activated Contentful extensions

In case you have multiple activated extensions, and have different mapping configurations for them. You can specify which extension instance you want to pull the configuration from when using the helper.

The helper receives an additional optional parameter for the extension instance. By default it is `0`, indicating the first activated extension.

The instances are sequentially numbered in order of activation, starting from 0.

So, if for example you have 2 active instances with different configuration, to use the second instance configuration, you should call the helper as: `rich_text(entry.rich_field, 1)`.

## Configuration: examples

```ruby
activate :contentful do |f|
  f.space         = {partners: 'space-id'}
  f.access_token  = 'some_access_token'
  f.cda_query     = { content_type: 'content-type-id', include: 1 }
  f.content_types = { partner: 'content-type-id'}
end
```

The above configuration does the following:

  * Sets the alias `partners` to the space with id _some-id_
  * Sets the alias `partner` to the content type with id _content-type-id_
  * Uses the default mapper to transform `partner` entries into yaml files (no mapper specified for the `partner` content type)

Entries fetched using this configuration will be stored as yaml files in `data/partners/partner/ENTRY_ID.yaml`.

```ruby
class Mapper
  def map(context, entry)
    context.title = "#{entry.title}-title"
    #...
  end
end

activate :contentful do |f|
  f.space         = {partners: 'space-id'}
  f.access_token  = 'some_access_token'
  f.cda_query     = { content_type: '1EVL9Bl48Euu28QEOa44ai', include: 1 }
  f.content_types = { partner: {mapper: Mapper, id: 'content-type-id'}}
end
```

The above configuration is the same as the previous one only that this time we are setting a custom mapper
for the entries belonging to the `partner` content type.


## Using imported entries in templates

Middleman will load all the yaml files stored in the local data folder. This lets you use all the imported
data into your templates.

Consider that we have data stored under `data/partners/partner`. Then in our templates we could use that data like
this:

```erb
<h1>Partners</h1>
<ol>
  <% data.partners.partner.each do |id, partner| %>
    <li><%= partner["name"] %></li>
  <% end %>
</ol>
```

### Rendering Markdown:

If you want to use markdown in your content types you manually have to render this to markdown.
Depending on the markdown library you need to transform the data.
For Kramdown this would be:

```
<%= Kramdown::Document.new(data).to_html %>
```

### Locales

If you have localized entries, and want to display content for multiple locales.
You can now include `locale: '*'` in your CDA query.

Then you have the following methods of accessing locales:

* **Manual access**

You can access your localized fields by fetching the locale directly from the data

```erb
<h1>Partners</h1>
<ol>
  <% data.partners.partner.each do |id, partner| %>
    <li><%= partner["name"]['en-US'] %></li>
  <% end %>
</ol>
```

* **Entry Helper**

You can also map an specific locale for all entry fields using `localize_entry`

```erb
<h1>Partners</h1>
<ol>
  <% data.partners.partner.each do |id, partner| %>
    <% localized_partner = localize_entry(partner, 'es') %>
    <li><%= localized_partner["name"] %></li>
  <% end %>
</ol>
```

* **Generic Field Helper**

The `localize` helper will map an specific locale to a field of your entry

```erb
<h1>Partners</h1>
<ol>
  <% data.partners.partner.each do |id, partner| %>
    <li>Value Field: <%= localize(partner, 'name', 'en-US') %></li>
    <li>Array Field: <%= localize(partner, 'phones', 'es') %></li>
  <% end %>
</ol>
```

* **Specific Field Type Helper**

Or, you can use `localize_value` or `localize_array` if you want more granularity.

> This method is discouraged, as `localize` achieves the same goal and is a field-type
agnostic wrapper of these methods.

```erb
<h1>Partners</h1>
<ol>
  <% data.partners.partner.each do |id, partner| %>
    <li>Value Field: <%= localize_value(partner['name'], 'en-US') %></li>
    <li>Array Field: <%= localize_array(partner['phones'], 'es') %></li>
  <% end %>
</ol>
```

If your fields are not localized, the value of the field will be returned.

In case of the field being localized but no value being set for a given entry, it will use
a fallback locale, by default is `en-US` but can be specified as an additional
parameter in all the mentioned calls.

### Preview API Helper

You can use the `#with_preview` helper to try your Preview API content without having to
generate the entire `data` structures.

This generates a new Preview Contentful Client and has a cache that will store your objects
in memory until they are considered to need refresh.

It can be used like a Contentful Client:

```erb
<% with_preview(space: 'cfexampleapi', access_token: 'b4c0n73n7fu1') do |preview| %>
  <% entry = preview.entry('nyancat') %>

  <p>Name: <%= entry.name %></p>
<% end %>
```

If you want to clear the cache to force a refresh:

```erb
<% with_preview(space: 'cfexampleapi', access_token: 'b4c0n73n7fu1') do |preview| %>
  <% preview.clear_cache %>
<% end %>
```

#### Caching Rules

* Every preview client will be cached by Space/Access Token combination
* Only `entry`, `entries`, `asset` and `assets` will be cached
* Every call will be cached by it's query parameters and ID (if ID is applicable)
* Each call will be considered, by default, stale after 3 tries or 2 hours
* Cache can be cleared by calling `#clear_cache`, this applies per preview client

#### Caching Configuration

You can configure `:tries` and `:expires_in` in the `#with_preview` call like this:

```erb
<% with_preview(
     space: 'cfexampleapi',
     access_token: 'b4c0n73n7fu1',
     tries: 20,                                                      # Set Tries to 20 before stale
     expires_in: ContentfulMiddleman::Tools::PreviewProxy.minutes(5) # Set Expiration to 5 minutes
   ) do |preview| %>
  <!-- do your stuff -->
<% end %>
```

## Platform Specific Deployment Caveats

For platform specific issues, please look into the [DEPLOYING](./DEPLOYING.md) document. This document is expected to grow with user contributions.
Feel free to add your own discoveries to that file by issuing a Pull Request.
