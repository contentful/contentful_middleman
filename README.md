# Contentful Middleman

[![Build Status](https://travis-ci.org/contentful/contentful_middleman.png)](https://travis-ci.org/contentful/contentful_middleman)

Contentful Middleman is a [Middleman](http://middlemanapp.com/) extension to use the Middleman static site generator together with the API-driven [Contentful CMS](https://www.contentful.com). It is powered by the [Contentful Ruby Gem](https://github.com/contentful/contentful.rb).

Experience the power of Middleman while staying sane as a developer by letting end-users edit content in a web-based interface.

This extensions supports both page-based content as well as blog posts through middleman-blog.

## Installation

Add the following line to the Gemfile of your Middleman project:

```
gem "contentful_middleman"
```

Then as usual, run:

```
bundle install
```

## Configuration

To configure the extension, add the following configuration block to Middleman's config.rb:

```
activate :contentful do |f|
  # The Space ID of your Contentful space
  f.space = 'YOUR_SPACE_ID'

  # The access token (API Key) for the Content Delivery API
  f.access_token = 'YOUR_CONTENT_DELIVERY_API_ACCESS_TOKEN'

  # Optional: Options for middleman-blog

  # Filter Entries for your blog posts. See Contentful gem and Content Delivery API documentation.
  f.blog_posts_query = {content_type: "6LbnqgnwA08qYaU", category: "news" } 
  
  # Which keys to use in the article template for blog posts
  # Key: template variable
  # Value: Entry method or block
  f.blog_post_mappings = {
      slug: :id,
      date: :created_at,
      body: :id,
      tags: :tags,
      title: ->(e){"#{e.id}XXXX"}
  }

  # Define your own template for blog posts
  f.new_article_template = "/my_templates/article.tt"

  # Automatically synchronize blog posts before building with "middleman build"
  f.sync_blog_before_build = true # default: false
end
```

## Using managed content in regular pages

The `contentful` helper provides a Contentful gem client object, that can be used to fetch managed content from Contentful:

```
  <ol>
    <% contentful.entries(content_type: '6LbnqgnwA08qYaU').each do |entry| %>
      <li>
        <%= entry.title %>
        <%= entry.body %>
        <%= entry.created_at %>
      </li>
    <% end %>
  </ol>
```

## Synchronizing blog posts manually

Blog posts are synchronized to your repo as YAML files with front matter, just as if you would write them manually. Either automatically when building, or manually by running:

```
middleman contentful
```
