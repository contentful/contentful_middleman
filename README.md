# Contentful Middleman

[![Build Status](https://travis-ci.org/contentful/contentful_middleman.png)](https://travis-ci.org/contentful/contentful_middleman)

Contentful Middleman is a [Middleman](http://middlemanapp.com/) extension to use the Middleman static side generator together with the API-driven [Contentful CMS](https://www.contentful.com). It is powered by the [Contentful Ruby Gem](https://github.com/contentful/contentful.rb).

Experience the power of Middleman while staying sane as a developer by letting end-users edit content in a web-based interface.

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

Run `$middleman contentful` in your terminal. This will fetch entries for the configured
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
  f.access_token  = ACCESS_TOKEN
  f.cda_query     = QUERY
  f.content_types = CONTENT_TYPES_MAPPINGS
end
```

Parameter | Description
----------|------------
space | Hash with an user choosen name for the space as key and the space id as value
access_token | Contentful Delivery API access token
cda_query | Hash describing query configuration. See [contentful.rb](https://github.com/contentful/contentful.rb) for more info
content_types | Hash describing the mapping applied to entries of the imported content types

You can activate the extension multiple times to import entries from different spaces.
## Entry mapping

The extension will transform every fetched entry before storing it as a yaml file in the local
data folder. If a custom mapper is not specified a default one will be used.

The default mapper will map fields, assets and linked entries.

### Custom mappers

You can create your own mappers if you need so. The only requirement for a class to behave as a
mapper is to have a `map(context, entry)` instance method. This method will take as parameters:

  * A context object. All properties set on this object will be written to the yaml file
  * An entry

Following is an example of such custom mapper:

```ruby
class MyAwesomeMapper
  def map(context, entry)
    context.slug = entry.title.parameterize
    #... more transformations
  end
end
```

If you don't want to map all the fields by hand inherit from the Base mappper:

```ruby
class MyAwesomeMapper < ContentfulMiddleman::Mappers::Base
  def map(context, entry)
    super
    # After calling super the context object
    # will have a property for every field in the
    # entry
  end
end
```

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

```html
<h1>Partners</h1>
<ol>
  <% data.partners.partner.each do |id, partner| %>
    <li><%= partner["name"] %></li>
  <% end %>
</ol>
```
